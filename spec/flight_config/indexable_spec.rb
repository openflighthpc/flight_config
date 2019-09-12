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

require 'flight_config/indexable'

RSpec.describe FlightConfig::Indexable do
  include_context 'with config utils'

  shared_examples 'does not delete the index' do
    with_existing_subject_file

    it 'does not error on data load' do
      expect do
        subject.__data__
      end.not_to raise_error
    end

    it 'does not delete the file' do
      begin
        subject.__data__
      rescue FlightConfig::InvalidIndex
        # noop
      end
      expect(File).to exist(subject.path)
    end
  end

  describe '::new' do
    def new_index
      config_class.new(subject_path)
    end

    subject { new_index }

    context 'with an invalid subject' do
      before { allow(subject).to receive(:valid?).and_return(false) }

      include_examples 'does not delete the index'
    end
  end

  describe '::read' do
    def read_subject
      config_class.read(subject_path)
    end

    subject { read_subject }
    before { allow(subject).to receive(:valid?).and_return(validity) }

    context 'with a valid subject' do
      let(:validity) { true }

      include_examples 'does not delete the index'
    end

    context 'with an exsting index' do
      with_existing_subject_file

      context 'with a valid subject' do
        let(:validity) { true }

        it { expect(File).to exist(subject.path) }
      end

      context 'with an invalid subject' do
        let(:validity) { false }

        it 'errors on data load' do
          expect do
            subject.__data__
          end.to raise_error(FlightConfig::InvalidIndex)
        end

        it 'deletes the file' do
          begin
            subject.__data__
          rescue FlightConfig::InvalidIndex
            # noop
          end
          expect(File).not_to exist(subject.path)
        end
      end
    end
  end

  describe '::create_or_update' do
    def create_or_update_index
      config_class.create_or_update(subject_path)
    end

    subject { create_or_update_index }

    shared_examples 'creates the index' do
      before { allow(subject).to receive(:valid?).and_return(true) }

      it_loads_empty_subject_config

      it 'ensures the file exists' do
        expect(File).to exist(subject.path)
      end
    end


    context 'without an existing config' do
      with_missing_subject_file

      include_examples 'creates the index'
    end

    context 'with an existing config' do
      with_existing_subject_file

      context 'without any initial data' do
        include_examples 'creates the index'
      end

      context 'with initial data' do
        before do
          File.write(subject_path, YAML.dump(key: 'I should not be loaded'))
        end

        include_examples 'creates the index'
      end
    end
  end
end
