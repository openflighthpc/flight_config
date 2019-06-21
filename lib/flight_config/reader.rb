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

require 'flight_config/core'

module FlightConfig
  class Registry
    def read(klass, *args)
      class_hash = (cache[klass] ||= {})
      arity_hash = (class_hash[args.length] ||= {})
      last_arg = args.pop
      last_hash = args.reduce(arity_hash) { |hash, arg| hash[arg] ||= {} }
      last_hash[last_arg] ||= klass.new(*args, last_arg, registry: self, read_mode: true)
    end

    private

    def cache
      @cache ||= {}
    end
  end

  module Reader
    include Core

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      include Core::ClassMethods

      def new!(*a, **h)
        new(*a, **h).tap do |config|
          yield config if block_given?
        end
      end

      def read(*a, registry: nil)
        (registry || Registry.new).read(self, *a)
      end
      alias_method :load, :read

      def read_or_new(*a)
        File.exists?(_path(*a)) ? read(*a) : new(*a)
      end
    end
  end
  Loader = Reader
end

