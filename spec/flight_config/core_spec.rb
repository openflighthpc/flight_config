#
# Copyright (c) 2019 Steve Norledge, Alces Flight
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
#  * Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#  * Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation and/or
# other materials provided with the distribution.
#  * Neither the name of the copyright holder nor the names of its contributors may be
# used to endorse or promote products derived from this software without specific
# prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

require 'flight_config/core'

require 'tempfile'

RSpec.describe FlightConfig::Core do
  include_context 'with config utils'

  subject { config_class.new(subject_path) }

  describe '::write' do
    shared_examples 'a standard write' do
      let(:new_subject_data) { nil }

      before do
        subject.__data__.set(:data, value: new_subject_data) if new_subject_data
        described_class.write(subject)
      end

      context 'without reading existing or saving new data' do
        it 'results in an existing file' do
          expect(File.exists?(subject.path)).to be_truthy
        end

        it 'saves the object as empty data' do
          new_subject = config_class.new(subject.path)
          described_class.read(new_subject)
          expect(new_subject.__data__.fetch(:data)).to eq(nil)
        end
      end

      context 'with new data' do
        let(:new_subject_data) { { "key" => 'new-value' } }

        it 'preforms a persistant save' do
          new_subject = config_class.new(subject.path)
          described_class.read(new_subject)
          expect(new_subject.__data__.fetch(:data)).to eq(new_subject_data)
        end
      end
    end

    context 'without an existing file' do
      with_missing_subject_file

      it_behaves_like 'a standard write'
    end

    context 'with existing data' do
      with_existing_subject_file
      let(:initial_subject_data) { { "initial_key" => 'initial value' } }

      it_behaves_like 'a standard write'
    end
  end

  describe '::lock' do
    shared_examples 'standard file lock' do
      it 'locks the file' do
        described_class.lock(subject) do
          File.open(subject.path, 'r+') do |file|
            expect(file.flock(File::LOCK_EX | File::LOCK_NB)).to be_falsey
          end
        end
      end
    end

    context 'with an existing file' do
      with_existing_subject_file

      it_behaves_like 'standard file lock'

      it 'throws a resource busy error if already locked' do
        Timeout.timeout(1) do
          File.open(subject.path, 'r+') do |file|
            file.flock(File::LOCK_SH)
            expect do
              described_class.lock(subject)
            end.to raise_error(FlightConfig::ResourceBusy)
          end
        end
      end
    end

    context 'without an existing file' do
      with_missing_subject_file

      it_behaves_like 'standard file lock'

      it 'deletes the file automatically' do
        described_class.lock(subject)
        expect(File.exists?(subject.path)).to be_falsey
      end
    end
  end

  describe '::new' do
    shared_examples 'set read mode' do
      describe '#__data__set_read_mode' do
        it 'changes the __data__mode to :read' do
          subject.__data__set_read_mode
          expect(subject.__data__mode).to eq(:read)
        end

        it 'errors if __data__ has been set' do
          subject.__data__
          expect do
            subject.__data__set_read_mode
          end.to raise_error(FlightConfig::BadModeError)
        end
      end
    end

    context 'without a config' do
      with_missing_subject_file

      it_uses__data__initialize
      include_examples 'set read mode'

      describe ':__data__read' do
        it 'raises MissingFile' do
          subject
          expect do
            subject.__data__read(TTY::Config.new)
          end.to raise_error(FlightConfig::MissingFile)
        end

        context 'with a lock' do
          it 'returns an empty object' do
            FlightConfig::Core.lock(subject) do
              subject.__data__read(subject.__data__)
            end
          end
        end
      end
    end

    context 'with a config' do
      with_existing_subject_file

      it_uses__data__initialize
      include_examples 'set read mode'

      describe ':__data__read' do
        context 'with nil data' do
          before { subject.__data__read(subject.__data__) }

          it 'is a empty data core' do
            expect(subject.__data__.to_h).to be_empty
          end
        end

        context 'with existing data' do
          let(:initial_subject_data) { { 'super-random': 4561 } }
          let(:input) { TTY::Config.new }

          context 'when reading to a different input' do
            before do
              subject.__data__
              subject.__data__read(input)
            end

            it 'does not implicitly change __data__' do
              expect(subject.__data__.to_h).to be_empty
            end

            it 'reads the data onto the input' do
              expect(input.fetch(:data)).to eq(initial_subject_data)
            end
          end

          context 'when reading within a file lock' do
            it 'reads the data' do
              FlightConfig::Core.lock(subject) do
                subject.__data__read(subject.__data__)
              end
              expect(subject.data).to eq(initial_subject_data)
            end
          end
        end
      end
    end
  end
end
