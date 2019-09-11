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

require 'flight_config/reader'
require 'flight_config/globber'

module FlightConfig
  module Indexable
    include FlightConfig::Reader
    include FlightConfig::Globber

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      include FlightConfig::Reader::ClassMethods

      def glob_read(*a)
        super.reject do |index|
          next if index.valid?
          FileUtils.rm_f path
          true
        end
      end

      def create_or_update(*a)
        new!(*a, read_mode: true) do |index|
          Core.log(index, "Generating index")
          FileUtils.mkdir_p File.dirname(index.path)
          FileUtils.touch index.path
        end
      end
    end

    def __data__
      {}
    end
  end
end
