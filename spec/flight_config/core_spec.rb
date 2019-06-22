#==============================================================================
# Copyright (C) 2019-present Alces Flight Ltd.
#
# This file is part of FlightConfig.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# FlightConfig is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with FlightConfig. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on FlightConfig, please visit:
# https://github.com/openflighthpc/flight_config
#==============================================================================
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

  describe '::new(read_mode: true)' do
    context 'without a config' do
      with_missing_subject_file

      subject { config_class.new(subject_path, read_mode: read_mode) }

      context 'without read_mode' do
        let(:read_mode) { false }

        it_uses__data__initialize
      end

      context 'with read mode' do
        let(:read_mode) { true }

        it 'raises MissingFile' do
          expect do
            subject.__data__
          end.to raise_error(FlightConfig::MissingFile)
        end

        context 'with allow_missing_read' do
          before do
            config_class.class_exec { allow_missing_read }
            subject.__data__
          end

          it 'returns an empty object' do
            expect(subject.__data__.to_h).to be_empty
          end
        end

        context 'with a lock' do
          it 'returns an empty object' do
            FlightConfig::Core.lock(subject) do
              subject.__data__
            end
            expect(subject.__data__.to_h).to be_empty
          end
        end
      end
    end

    context 'with a config' do
      with_existing_subject_file

      subject { config_class.new(subject_path, read_mode: read_mode) }

      context 'without read_mode' do
        let(:read_mode) { false }

        it_uses__data__initialize
      end

      describe ':with read mode' do
        let(:read_mode) { true }

        context 'with nil data' do
          before { subject.__data__ }

          it 'is a empty data core' do
            expect(subject.__data__.to_h).to be_empty
          end
        end

        context 'with existing data' do
          let(:initial_subject_data) { { 'super-random': 4561 } }

          context 'when reading within a file lock' do
            it 'reads the data' do
              FlightConfig::Core.lock(subject) do
                subject.__data__
              end
              expect(subject.data).to eq(initial_subject_data)
            end
          end
        end
      end
    end
  end
end
