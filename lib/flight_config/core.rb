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

require 'flight_config/patches/tty_config'

module FlightConfig
  module Core
    PLACEHOLDER = '__flight_config_placeholder__'

    def self.read(obj)
      return unless File.exists?(obj.path)
      str = File.read(obj.path)
      data = (str == PLACEHOLDER ? nil : YAML.load(str))
      return if data.nil?
      obj.__data__.merge(data)
    end

    def self.write(obj)
      FileUtils.mkdir_p(File.dirname(obj.path))
      obj.__data__.write(obj.path, force: true)
    end

    def self.lock(obj)
      placeholder = false
      unless File.exists?(obj.path)
        placeholder = true
        File.write(obj.path, PLACEHOLDER)
      end
      yield
    ensure
      if placeholder && File.read(obj.path) == PLACEHOLDER
        FileUtils.rm_f(obj.path)
      end
    end

    def __data__
      @__data__ ||= TTY::Config.new
    end

    def path
      raise NotImplementedError
    end
  end
end
