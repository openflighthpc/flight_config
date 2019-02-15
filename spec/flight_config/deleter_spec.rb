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

RSpec.describe FlightConfig::Deleter do
  include_context 'with config utils', FlightConfig::Reader

  describe '::delete' do
    def delete_config(&b)
      config_class.delete(subject_path, &b)
    end

    subject { delete_config }

    context 'without an existing file' do
      with_missing_subject_file

      it_raises_missing_file
    end

    context 'with an existing file' do
      with_existing_subject_file

      it_freezes_the_subject_data
      it_locks_the_file(:delete)

      it 'removes the file' do
        expect(File.exists?(subject.path)).to be_falsey
      end

      it 'removes the file for truthy blocks' do
        config = delete_config { true }
        expect(File.exists?(config.path)).to be_falsey
      end

      it 'updates the config if the block returns false' do
        new_data = 'data added in delete'
        config = delete_config do |c|
          c.data = new_data
          false
        end
        expect(config_class.read(config.path).data).to eq(new_data)
      end

      it_behaves_like_initial_subject_data_reader
    end
  end
end

