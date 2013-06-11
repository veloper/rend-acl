module Rend
  class Acl
    class Assertion
      # Returns true if and only if the assertion conditions are met
      #
      # This method is passed the ACL, Role, Resource, and privilege to which the authorization query applies. If the
      # $role, $resource, or $privilege parameters are nil, it means that the query applies to all Roles, Resources, or
      # privileges, respectively.
      #
      # @param  Zend_Acl                    $acl
      # @param  Zend_Acl_Role_Interface     $role
      # @param  Zend_Acl_Resource_Interface $resource
      # @param  string                      $privilege
      # @return boolean
      def pass?(acl, role = nil, resource = nil, privilege = nil)
        type_hint! Rend::Acl, acl, :is_required => true
        type_hint! Rend::Acl::Role, role
        type_hint! Rend::Acl::Resources, resource
        type_hint! String, privilege
      end

    end
  end
end