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
require 'flight_config/globber'

RSpec.describe FlightConfig::Globber do
  let(:glob_class) do
    nodule = described_class
    Class.new do
      include FlightConfig::Reader
      include nodule

      attr_reader :path, :args

      def initialize(*args)
        @args = args
        parts = args.map { |arg| "var/#{arg}" }
        @path = File.join('/tmp', *parts, 'etc/config.yaml')
      end
    end
  end

  describe '::glob_read' do
    include_fakefs

    shared_examples 'with variable initializer' do
      let(:input_args) { Array.new(num_inputs, '*') }
      subject { glob_class.glob_read(*input_args) }

      context 'without any existing configs' do
        it 'returns an empty array' do
          expect(subject).to eq([])
        end
      end

      context 'with a single existing configs' do
        let(:name) { 'first-test-config' }
        let(:name_args) do
          args = Array.new(num_inputs) { |i| "arg#{i}" }
          args[-1] = name
          args
        end

        before do
          path = glob_class.new(*name_args).path
          FileUtils.mkdir_p(File.dirname(path))
          FileUtils.touch(path)
        end

        it 'finds a single config' do
          expect(subject.length).to be(1)
        end

        it 'returns objects of the correct type' do
          expect(subject.first.class).to eq(glob_class)
        end

        it 'resolves the arguments correctly' do
          expect(subject.first.args).to eq(name_args)
        end
      end
    end

    context 'with a single input initializer' do
      let(:num_inputs) { 1 }
      include_examples 'with variable initializer'
    end

    context 'with a single input initializer' do
      let(:num_inputs) { 3 }
      include_examples 'with variable initializer'
    end
  end
end
