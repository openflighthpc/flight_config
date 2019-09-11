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
  describe '::create_or_update' do
    include_context 'with config utils'

    def create_or_update_index
      config_class.create_or_update(subject_path)
    end

    subject { create_or_update_index }

    shared_examples 'creates the index' do
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

      include_examples 'creates the index'
    end
  end
end
