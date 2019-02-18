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

require 'flight_config/reader'

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
      it_freezes_the_subject_data

      it_behaves_like_initial_subject_data_reader

      it 'ignores the file lock' do
        FlightConfig::Core.lock(subject) do
          expect do
            Timeout.timeout(1) { read_subject }
          end.not_to raise_error
        end
      end
    end
  end

  describe '::glob_read' do
    include_fakefs

    shared_examples 'with arity' do |num_inputs|
      let(:input_args) { Array.new(num_inputs, nil) }
      subject { glob_class.glob_read(*input_args) }

      context "when initialized with #{num_inputs} input(s)" do
        context 'without any existing configs' do
          it 'returns an empty array' do
            expect(subject).to eq([])
          end
        end

        context 'with a single existing configs' do
          let(:name) { 'first-test-config' }

          before do
            path = glob_class.new(name).path
            FileUtils.mkdir_p(File.dirname(path))
            FileUtils.touch(path)
          end

          xit 'finds a single config' do
            expect(subject.length).to be(1)
          end
        end
      end
    end

    let(:glob_class) do
      nodule = described_class
      Class.new do
        include nodule

        attr_reader :path

        def initialize(*a)
          parts = a.map { |arg| "var/#{arg}" }
          @path = File.join('/tmp', *parts, 'etc/config.yaml')
        end
      end
    end

    include_examples 'with arity', 1
    include_examples 'with arity', 3
  end
end
