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
RSpec.describe FlightConfig::Updater do
  include_context 'with config utils'

  shared_examples 'modifier method' do |method|
    it_locks_the_file(method)

    it 'guarantees the file exists' do
      expect(File.exist?(subject.path)).to be_truthy
    end

    it 'updates the config' do
      str = 'new configuration value'
      config = config_class.public_send(method, subject_path) do |c|
        c.data = str
      end
      expect(config_class.read(config.path).data).to eq(str)
    end
  end

  describe '::create' do
    def create_config(&b)
      config_class.create(subject_path, &b)
    end

    subject { create_config }

    context 'with an existing config' do
      with_existing_subject_file

      it 'errors' do
        expect { create_config }.to raise_error(FlightConfig::CreateError)
      end
    end

    context 'without an existing config' do
      with_missing_subject_file

      it_behaves_like 'modifier method', :create

      it_uses__data__initialize
    end
  end

  describe '::create_or_update' do
    def create_or_update_config(&b)
      config_class.create_or_update(subject_path, &b)
    end

    subject { create_or_update_config }

    context 'without an existing config' do
      with_missing_subject_file

      it_behaves_like 'modifier method', :create_or_update

      it_uses__data__initialize
    end

    context 'with an existing config' do
      with_existing_subject_file

      it_behaves_like 'modifier method', :create_or_update

      it_uses__data__read
    end
  end

  describe '::update' do
    def update_config(&b)
      config_class.update(subject_path, &b)
    end

    subject { update_config }

    context 'without an existing config' do
      with_missing_subject_file

      it_raises_missing_file
    end

    context 'with an existing config' do
      with_existing_subject_file

      it_behaves_like 'modifier method', :update

      it_uses__data__read
    end
  end
end
