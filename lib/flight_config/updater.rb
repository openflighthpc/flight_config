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
require 'flight_config/reader'

module FlightConfig
  module Updater
    include Core

    def self.included(base)
      base.extend(ClassMethods)
    end

    def self.create_or_update(config, action:)
      Core.log(config, action)
      Core.lock(config) do
        config.__data__
        yield config if block_given?
        Core.log(config, "#{action} (write)")
        Core.write(config)
      end
      Core.log(config, "#{action} (done)")
    end

    def self.create_error_if_exists(config)
      return unless File.exist?(config.path)
      raise CreateError, <<~ERROR.chomp
        Create failed! The config already exists: #{config.path}
      ERROR
    end

    def self.update_error_if_missing(config)
      return if File.exists?(config.path)
      raise MissingFile, <<~ERROR.chomp
        Update failed! The config does not exist: #{config.path}
      ERROR
    end

    module ClassMethods
      include Reader::ClassMethods

      def update(*a, &b)
        new!(*a, read_mode: true) do |config|
          Updater.update_error_if_missing(config)
          Updater.create_or_update(config, action: 'update', &b)
        end
      end

      def create_or_update(*a, &b)
        mode = File.exists?(_path(*a))
        new!(*a, read_mode: mode) do |config|
          Updater.create_or_update(config, action: 'create_or_update', &b)
        end.tap { |c| c.generate_indices if c.respond_to?(:generate_indices) }
      end

      def create(*a, &b)
        new!(*a) do |config|
          Updater.create_error_if_exists(config)
          Updater.create_or_update(config, action: 'create', &b)
        end
      end
    end
  end
end
