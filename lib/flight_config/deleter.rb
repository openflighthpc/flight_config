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
require 'flight_config/exceptions'
require 'flight_config/core'

module FlightConfig
  module Deleter
    def self.included(base)
      base.extend(ClassMethods)
    end

    def self.delete_error_if_missing(config)
      return if File.exist?(config.path)
      raise MissingFile, <<~ERROR.chomp
        Delete failed! The config does not exist: #{config.path}
      ERROR
    end

    module ClassMethods
      def delete(*a)
        new!(*a, read_mode: true) do |config|
          Deleter.delete_error_if_missing(config)
          Core.log(config, 'delete')
          Core.lock(config) do
            config.__data__
            if block_given? && !(yield config)
              Core.log(config, 'delete (failed)')
              Core.write(config)
              Core.log(config, 'delete (saved)')
            else
              FileUtils.rm_f(config.path)
              Core.log(config, 'delete (done)')
            end
          end
        end
      end
    end
  end
end
