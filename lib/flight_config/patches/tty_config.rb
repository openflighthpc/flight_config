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

require 'tty/config'
require 'yaml'

module FlightConfig
  module Patches
    module TTYConfig
      ##
      # Redefine TTY::Config to use the custom YAML parser
      #
      def self.included(base)
        base.const_set('YAML', PatchedYAML)
      end

      module PatchedYAML
        ##
        # Overload `safe_load` to always allow aliases
        #
        def self.safe_load(yaml,
                           whitelist_classes = [],
                           whitelist_symbols = [],
                           _aliases = false,
                           filename = nil)
          Psych.safe_load(yaml,
                          whitelist_classes,
                          whitelist_symbols,
                          true,
                          filename)
        end


        ##
        # Delegate missing methods to Psych
        #
        def self.method_missing(s, *a, **h, &b)
          if respond_to_missing?(s) == :psych_method
            Psych.public_send(s, *a, **h, &b)
          else
            super
          end
        end

        ##
        # Check if the missing method is defined on Psych
        #
        def self.respond_to_missing?(s)
          return :psych_method if Psych.respond_to?(s)
          super
        end
      end
    end

    TTY::Config.include TTYConfig
  end
end

