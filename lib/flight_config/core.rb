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
require 'flight_config/log'
require 'flight_config/patches/tty_config'
require 'flight_config/registry'
require 'timeout'

module FlightConfig
  module Core
    PLACEHOLDER = '__flight_config_placeholder__'

    def self.included(base)
      base.extend(ClassMethods)
    end

    def self.log(obj, action)
      Log.info "#{action}: #{obj.path}"
    end

    # Deprecated: The mode can be switched directly on the object
    def self.read(obj)
      obj.instance_variable_set(:@__read_mode__, true)
      obj.instance_variable_set(:@__data__, nil)
      obj.__data__
    end

    def self.write(obj)
      FileUtils.mkdir_p(File.dirname(obj.path))
      obj.__data__.write(obj.path, force: true)
    end

    def self.lock(obj)
      placeholder = false
      io = nil
      unless File.exists?(obj.path)
        Core.log(obj, 'placeholder')
        placeholder = true
        FileUtils.mkdir_p(File.dirname(obj.path))
        File.write(obj.path, PLACEHOLDER)
      end
      begin
        io = File.open(obj.path, 'r+')
        Timeout.timeout(0.1) { io.flock(File::LOCK_EX) }
      rescue Timeout::Error
        raise ResourceBusy, "The following resource is busy: #{obj.path}"
      end
      yield if block_given?
    ensure
      io&.close
      if placeholder && File.read(obj.path) == PLACEHOLDER
        FileUtils.rm_f(obj.path)
        Core.log(obj, 'placeholder (removed)')
      end
    end

    module ClassMethods
      def path(*_input_args)
        raise NotImplementedError
      end

      def allow_missing_read(fetch: false)
        if fetch
          @allow_missing_read ||= false
        else
          @allow_missing_read = true
        end
      end

      def new__data__
        TTY::Config.new
      end
    end

    attr_reader :__inputs__, :__read_mode__

    def initialize(*input_args, registry: nil, read_mode: nil)
      @__inputs__ = input_args
      @__registry__ = registry
      @__read_mode__ = read_mode
    end

    def __registry__
      @__registry__ ||= FlightConfig::Registry.new
    end

    def __data__initialize(_tty_config)
    end

    def __data__read(tty_config)
      if File.exists?(path)
        Core.log(self, 'read')
        str = File.read(path)
        yaml_h = (str == Core::PLACEHOLDER ? nil : YAML.load(File.read(path)))
        return unless yaml_h
        tty_config.merge(yaml_h)
      elsif self.class.allow_missing_read(fetch: true)
        Core.log(self, 'missing (skip read)')
      else
        raise MissingFile, "The file does not exist: #{path}"
      end
    end

    def __data__
      @__data__ ||= self.class.new__data__.tap do |core|
        if __read_mode__
          __data__read(core)
        else
          __data__initialize(core)
        end
      end
    end

    def path
      @path ||= self.class.path(*__inputs__)
    end
  end
end
