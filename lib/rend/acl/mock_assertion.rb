# Not a required file -- used for testing
module Rend
  class Acl
    class MockAssertion < Rend::Acl::Assertion

      attr_reader   :last_acl
      attr_reader   :last_role
      attr_reader   :last_resource
      attr_reader   :last_privilege

      attr_accessor :pass

      def initialize(pass = nil, &block)
        self.pass = block_given? ? block : pass
      end

      def pass=(value)
        @pass = value.is_a?(Proc) ? value : lambda {|acl, role, resource, privilege| value}
      end

      def pass?(acl, role = nil, resource = nil, privilege = nil)
        @last_acl, @last_role, @last_resource, @last_privilege = acl, role, resource, privilege
        pass.call(acl, role, resource, privilege)
      end

    end
  end
end