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

module FlightConfig
  module Links
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      include Globber::ClassMethods

      def define_link(key, klass, glob: false, &b)
        links_class.define_method(key) do
          args = config.instance_exec(&b)
          method = (glob ? :glob_read : :read)
          klass.public_send(method, *args, registry: config.__registry__)
        end
      end

      def links_class
        @links_class ||= Struct.new(:config)
      end
    end

    def links
      @links ||= self.class.links_class.new(self)
    end
  end
end
