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
    end
  end
end
