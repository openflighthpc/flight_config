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
RSpec.shared_context 'with config utils' do |*additional_includes|
  def self.with_existing_subject_file
    let!(:subject_file) do
      Tempfile.create(*temp_file_input).tap do |file|
        file.write(YAML.dump(initial_data_hash)) unless initial_subject_data.nil?
        file.flush
      end
    end
    let(:subject_path) { subject_file.path }

    after do
      begin
        File.unlink(subject_file)
      rescue Errno::ENOENT
        # :noop: The file has already been deleted
      end
    end
  end

  def self.with_missing_subject_file
    let(:subject_path) do
      file = Tempfile.new(*temp_file_input)
      path = file.path
      file.close
      file.unlink
      path
    end

    after { FileUtils.rm_f subject_path }
  end

  def self.it_loads_empty_subject_config
    it 'loads an empty hash equivalent TTY::Config object' do
      expect(subject.__data__).to be_a(TTY::Config)
      expect(subject.__data__.to_h).to be_empty
    end
  end

  def self.it_locks_the_file(method)
    it 'runs the block in a file lock' do
      config_class.public_send(method, subject_path) do |config|
        File.open(config.path, 'r+') do |file|
          expect(file.flock(File::LOCK_EX|File::LOCK_NB)).to be_falsey
        end
      end
    end
  end

  def self.it_raises_missing_file
    it 'raises MissingFile' do
      expect { subject }.to raise_error(FlightConfig::MissingFile)
    end
  end

  def self.it_uses__data__initialize
    it 'uses __data__initialize' do
      subject.instance_variable_set(:@__data__, nil)
      expect(subject).to receive(:__data__initialize).with(instance_of(TTY::Config))
      subject.__data__
    end

    it 'does not use __data__read' do
      subject.instance_variable_set(:@__data__, nil)
      expect(subject).not_to receive(:__data__read)
      subject.__data__
    end

    it 'can set a default useing the TTY::Config initializer' do
      value = '__data__initializer-value'
      config_class.define_method(:__data__initialize) do |config|
        config.set(:key, value: value)
      end
      expect(subject.__data__.fetch(:key)).to eq(value)
    end
  end

  def self.it_uses__data__read
    it 'uses __data__read' do
      subject.instance_variable_set(:@__data__, nil)
      expect(subject).to receive(:__data__read).with(instance_of(TTY::Config))
      subject.__data__
    end

    it 'does not use __data__initialize' do
      subject.instance_variable_set(:@__data__, nil)
      expect(subject).not_to receive(:__data__initialize)
      subject.__data__
    end

    context 'without any initial data' do
      let(:initial_subject_data) { nil }

      it 'loads an empty data core' do
        subject.instance_variable_set(:@__data__, nil)
        expect(subject.__data__.to_h).to be_empty
      end
    end

    context 'with initial data' do
      let(:initial_subject_data) { { 'data_read': 'it worked' } }

      it 'loads in the data' do
        expect(subject.data).to eq(initial_subject_data)
      end
    end
  end

  let(:temp_file_input) { [['rspec_flight_config', '.yaml'], '/tmp'] }

  let(:config_class) do
    classes = [*additional_includes, described_class].flatten
    Class.new do
      classes.each { |c| include c }

      attr_reader :path

      def initialize(path)
        @path = path
      end

      def data=(input)
        __data__.set(:data, value: input)
      end

      def data
        __data__.fetch(:data)
      end
    end
  end

  let(:subject_path) do
    raise NotImplementedError
  end

  let(:initial_subject_data) { nil }

  let(:initial_data_hash) { { "data" => initial_subject_data } }
end
