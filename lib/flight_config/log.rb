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
require 'logger'

module FlightConfig
  class << self
    attr_accessor :logger

    def default_log_path
      '/tmp/flight_config.log'
    end
  end

  module Log
    def self.method_missing(s, *a, &b)
      status = respond_to_missing?(s)
      if status == :log_method
        FlightConfig.logger.send(s, *a, &b)
      elsif status == :nil_logger
        # noop
      else
        super
      end
    end

    def self.respond_to_missing?(s)
      return :log_method if FlightConfig.logger.respond_to?(s)
      return :nil_logger if FlightConfig.logger.nil?
      super
    end
  end
end
