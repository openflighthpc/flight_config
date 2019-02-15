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
  let(:subject_path) { raise NotImplementedError }
  let(:temp_file_input) { [['rspec_flight_config', '.yaml'], '/tmp'] }

  subject do
    klass = described_class
    Class.new do
      include klass

      attr_reader :path

      def initialize(path)
        @path = path
      end

      def data
        __data__.fetch(:data)
      end
    end.new(subject_path)
  end

  shared_context 'with an existing subject' do
    let!(:subject_file) do
      Tempfile.create(*temp_file_input).tap do |file|
        file.write(YAML.dump(initial_data_hash)) unless initial_subject_data.nil?
        file.flush
      end
    end
    let(:subject_path) { subject_file.path }
    let(:initial_subject_data) { nil }
    let(:initial_data_hash) { { data: initial_subject_data } }

    after { File.unlink(subject_file) }
  end

  shared_context 'with a non existant subject' do
    let(:subject_path) do
      file = Tempfile.new(*temp_file_input)
      path = file.path
      file.close
      file.unlink
      path
    end

    after { FileUtils.rm_f subject_path }
  end

  describe '::read' do
    context 'without an existing file' do
      include_context 'with a non existant subject'

      it 'errors' do
        expect do
          described_class.read(subject)
        end.to raise_error(Errno::ENOENT)
      end
    end

    context 'with an existing file' do
      include_context 'with an existing subject'

      before { described_class.read(subject) }

      it 'loads an empty hash equivalent TTY::Config object' do
        expect(subject.__data__).to be_a(TTY::Config)
        expect(subject.__data__.to_h).to be_empty
      end

      context 'with existing hash data' do
        let(:initial_subject_data) { { key: 'value' } }

        it 'loads in the existing data' do
          expect(subject.data).to eq(initial_subject_data)
        end
      end
    end
  end

  describe '::write' do
    shared_examples 'a standard write' do
      before { described_class.write(subject) }

      it 'writes the file' do
        expect(File.exists?(subject.path)).to be_truthy
      end
    end

    context 'without an existing file' do
      include_context 'with a non existant subject'

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
      include_context 'with an existing subject'

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
      include_context 'with a non existant subject'

      it_behaves_like 'standard file lock'

      it 'deletes the file automatically' do
        described_class.lock(subject)
        expect(File.exists?(subject.path)).to be_falsey
      end
    end
  end
end
