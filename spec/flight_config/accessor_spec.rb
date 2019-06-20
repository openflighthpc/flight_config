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

require 'flight_config/accessor'

RSpec.describe FlightConfig::Accessor do
  include_context 'with config utils', FlightConfig::Reader
  with_existing_subject_file
  let(:key) { :test_key }
  let(:block_key) { :test_block_key }
  let(:yield_spec_key) { :test_yield_spec_key }

  let(:key_eq) { :"#{key}=" }
  let(:block_key_eq) { :"#{block_key}=" }
  let(:yield_spec_key_eq) { :"#{yield_spec_key}=" }

  let(:value) { 'initial-value' }
  let(:initial_data_hash) do
    {
      key => value,
      block_key => value,
      yield_spec_key => value
    }
  end

  subject { config_class.read(subject_path) }

  describe '::data_reader' do
    before { config_class.data_reader(key) }

    it 'defines the reader instance method' do
      expect(config_class.instance_methods).to include(key)
    end

    it 'returns the value' do
      expect(subject.send(key)).to eq(value)
    end

    context 'with a block' do
      let(:result) { 'I am the result value' }
      let(:block) { r = result; proc { |_| r } }

      before { config_class.data_reader(block_key, &block) }

      it 'yields the saved value' do
        expect do |b|
          config_class.data_reader(yield_spec_key, &b)
          subject.send(yield_spec_key)
        end.to yield_with_args(value)
      end

      it 'returns the result of the block' do
        expect(subject.send(block_key) { |_| result }).to eq(result)
      end
    end
  end

  describe '::data_writer' do
    let(:initial_data_hash) { nil }
    let(:new_value) { 'a different value from data_reader' }

    before do
      config_class.data_reader(key)
      config_class.data_writer(key)
    end

    it 'defines the writer instance method' do
      expect(config_class.instance_methods).to include(key_eq)
    end

    it 'returns the new value' do
      subject.send(key_eq, new_value)
      expect(subject.send(key)).to eq(new_value)
    end
  end
end
