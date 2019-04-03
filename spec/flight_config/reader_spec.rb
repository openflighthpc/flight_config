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
require 'flight_config/reader'
require 'flight_config/globber_spec'

RSpec.describe FlightConfig::Reader do
  describe '::read' do
    include_context 'with config utils'

    def read_subject
      config_class.read(subject_path)
    end

    subject { read_subject }

    context 'without an existing file' do
      with_missing_subject_file

      it_raises_missing_file

      context 'with allow_missing_read' do
        before { config_class.allow_missing_read }

        it 'does not error' do
          expect { subject }.not_to raise_error
        end

        it_loads_empty_subject_config
      end
    end

    context 'with an existing file' do
      with_existing_subject_file

      it_loads_empty_subject_config
      it_uses__data__read

      it 'ignores the file lock' do
        FlightConfig::Core.lock(subject) do
          expect do
            Timeout.timeout(1) { read_subject }
          end.not_to raise_error
        end
      end
    end
  end
end

