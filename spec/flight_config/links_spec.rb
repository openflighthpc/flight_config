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

require 'flight_config/links'

RSpec.describe FlightConfig::Links do
  include_context 'with config utils', FlightConfig::Reader

  let(:subject_path) { '/tmp/test/path' }
  subject { config_class.read(subject_path) }

  let(:other_path) { '/tmp/to/somewhere/else' }
  let(:other_config) { Class.new(config_class) }

  let(:glob_path) { '/this/path/intentionally/should/not/exist/hopefully?' }

  before do
    # Save the methods as a variables so they are handed down with the closure
    other_c = other_config
    other_p = other_path
    glob_p = glob_path
    config_class.class_exec do
      define_link(:return_me, self) { [self.path] }
      define_link(:return_other, other_c) { [other_p] }
      define_link(:return_array, self, glob: true) { [glob_p] }
    end
  end

  it 'defines the link method' do
    expect(subject.links).to respond_to(:return_me)
  end

  it 'can preform a link to itself' do
    expect(subject.links.return_me).to eq(subject)
  end

  it 'can link to a different object' do
    expect(subject.links.return_other).to be_a(other_config)
  end

  it 'sets the other config path' do
    expect(subject.links.return_other.path).to eq(other_path)
  end

  it 'can glob for configs' do
    expect(subject.class).to receive(:glob_read).with(
      glob_path, registry: subject.__registry__
    ).once
    subject.links.return_array
  end

  it 'returns an array when globbing' do
    expect(subject.links.return_array).to be_a(Array)
  end
end

