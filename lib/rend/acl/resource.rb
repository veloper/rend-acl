module Rend
  class Acl
    class Resource

      # Unique id of Resource
      attr_reader :id # @var string

      def initialize(id)
        @id = id.to_s
      end

    end
  end
end
