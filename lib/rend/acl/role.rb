require 'rend/acl/role/registry'

module Rend
  class Acl
    class Role

      # Unique id of Role
      attr_reader :id # @var string

      def initialize(id)
        @id = id.to_s
      end

      def to_s
        @id
      end

    end
  end
end