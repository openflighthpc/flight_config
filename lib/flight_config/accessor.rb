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

# NOTE: This is compatibility layer between the accessor and TTY::Config.
# TTY::Config isn't a good match with FlightConfig as they both try and preform
# the file handling. Instead a Hashie type object should be used.
#
# To facilitate the transition, the accessors use the standard [] and []= methods
# as these will be defined on most hashie objects. TTY::Config does not implement
# them however. Hence the need for the compatibility layer

module FlightConfig
  module TTYConfigAccessor
    def [](key)
      fetch(key)
    end

    def []=(key, value)
      if value.nil?
        delete(key)
      else
        set(key, value: value)
      end
    end
  end

  TTY::Config.include(TTYConfigAccessor)
end

module FlightConfig
  module Accessor
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def data_accessor(key)
        data_reader(key)
        data_writer(key)
      end

      def data_reader(key)
        self.define_method(key) do
          __data__[key]
        end
      end

      def data_writer(key)
        self.define_method("#{key}=") do |value|
          __data__[key] = value
        end
      end
    end
  end
end
