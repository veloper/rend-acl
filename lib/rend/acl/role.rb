require 'rend/acl/role/registry'
module Rend
  class Acl
    class Role

      # Unique id of Role
      attr_reader :id # @var string
      # attr_accessor :parents  -- future
      # attr_accessor :children -- future

      def initialize(id)
        @id = id.to_s
        # @parents = {}  -- future
        # @children = {} -- future
      end

    end
  end
end