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
RSpec.describe FlightConfig::Deleter do
  include_context 'with config utils', FlightConfig::Reader

  describe '::delete' do
    def delete_config(&b)
      config_class.delete(subject_path, &b)
    end

    let(:subject_block) { nil }
    subject { delete_config(&subject_block) }

    context 'without an existing file' do
      with_missing_subject_file

      it_raises_missing_file
    end

    context 'with an existing file' do
      with_existing_subject_file

      it_locks_the_file(:delete)

      it 'removes the file' do
        expect(File.exists?(subject.path)).to be_falsey
      end

      it 'removes the file for truthy blocks' do
        config = delete_config { true }
        expect(File.exists?(config.path)).to be_falsey
      end

      context 'with a delete block that returns false' do
        let(:subject_block) { proc { |_| false } }

        # The block must return false otherwise the file is deleted
        # and it_uses__data__read will error
        it_uses__data__read

        it 'updates the config if the block returns false' do
          new_data = 'data added in delete'
          config = delete_config do |c|
            c.data = new_data
            false
          end
          expect(config_class.read(config.path).data).to eq(new_data)
        end
      end
    end
  end
end

