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

