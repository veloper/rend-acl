require 'rend/core'

require 'rend/acl/version'
require 'rend/acl/exception'
require 'rend/acl/role'
require 'rend/acl/resource'
require 'rend/acl/assertion'

module Rend
  class Acl
    include Rend::Core::Helpers::Php

    TYPE_ALLOW  = :TYPE_ALLOW
    TYPE_DENY   = :TYPE_DENY
    OP_ADD      = :OP_ADD
    OP_REMOVE   = :OP_REMOVE

    def initialize
      # @var Rend::Acl::Role::Registry
      @_role_registry = nil

      # @var Hash
      @_resources = {}

      # @var Rend::Acl::Role
      @_is_allowed_role     = nil

      # @var Rend::Acl::Resource
      @_is_allowed_resource = nil

      # @var String
      @_is_allowed_privilege = nil

      # ACL rules whitelist (deny everything to all) by default
      # @var Hash
      @_rules = {
        :all_resources => {
          :all_roles => {
            :all_privileges => {
              :type       => TYPE_DENY,
              :assertion  => nil
            },
            :by_privilege_id => {}
          },
          :by_role_id => {}
        },
        :by_resource_id => {}
      }
    end

    # Adds Roles & Resources in various ways.
    #
    # - Roles
    #   - Arguments
    #     .add! Rend::Acl::Role.new("editor")                                             # Single Role
    #     .add! Rend::Acl::Role.new("editor"), 'guest'                                    # Single Role w/ Single Inheritance
    #     .add! Rend::Acl::Role.new("editor"), ['guest', 'contributor']                   # Single Role w/ Multiple Inheritance
    #   - Hash
    #     .add! :role => 'editor'                                                         # Single Role
    #     .add! :role => {'editor' => 'guest'}                                            # Single Role w/ Single Inheritance
    #     .add! :role => {'editor' => ['guest', 'contributor']}                           # Single Role w/ Multiple Inheritance
    #     .add! :role => ['guest', 'editor']                                              # Multiple Roles
    #     .add! :role => ['guest', 'contributor', {'editor' => 'guest'}]                  # Multiple Roles w/ Single Inheritance
    #     .add! :role => ['guest', 'contributor', {'editor' => ['guest', 'contributor']}] # Multiple Roles w/ Multiple Inheritance
    # - Resources
    #   - Arguments
    #     .add! Rend::Acl::Resource.new("city")                                           # Single Resource
    #     .add! Rend::Acl::Resource.new("building"), 'city'                               # Single Resource w/ Inheritance
    #   - Hash
    #     .add! :resource => 'city'                                                       # Single Resource
    #     .add! :resource => {'building' => 'city'}                                       # Single Resource w/ Inheritance
    #     .add! :resource => ['city', 'building']                                         # Multiple Resources
    #     .add! :resource => ['city', 'building', {'building' => 'city'}]                 # Multiple Resources w/ Inheritance
    # - Combined Roles & Resources
    #     .add! :role => ['guest', {'editor' => 'guest'}], :resource => ['city', {'building' => 'city'}]
    #
    def add!(*args)
      raise ArgumentError, "wrong number of arguments(0 for 1..2)" if args.empty?
      method_args = {:role => [], :resource => []}
      case args[0]
      when Rend::Acl::Role      then method_args[:role]     << args
      when Rend::Acl::Resource  then method_args[:resource] << args
      when Hash
        args[0].each do |key, value|
          if [:role, :resource].include?(key.to_sym)
            case value
            when String then method_args[key] << value
            when Hash   then method_args[key] << value.flatten
            when Array  then value.each {|x| method_args[key] << (x.is_a?(Hash) ? x.flatten : x) }
            else
              raise Rend::Acl::Exception, "Invalid value (#{value.inspect}) for key (#{key.to_s}) in options hash."
            end
          else
            raise Rend::Acl::Exception, "Invalid key (#{key.to_s}) in options hash."
          end
        end
      else
        raise Rend::Acl::Exception, "First argument is not an instance of Rend::Acl::Role, Rend::Acl::Resource, or Hash."
      end
      method_args.each do |type, arguments|
        method = "add_#{type.to_s}!".to_sym
        arguments.each {|args| send(method, *args)}
      end
      self
    end

    # Adds a Role having an identifier unique to the registry
    #
    # The parents parameter may be a reference to, or the string identifier for,
    # a Role existing in the registry, or parents may be passed as an array of
    # these - mixing string identifiers and objects is ok - to indicate the Roles
    # from which the newly added Role will directly inherit.
    #
    # In order to resolve potential ambiguities with conflicting rules inherited
    # from different parents, the most recently added parent takes precedence over
    # parents that were previously added. In other words, the first parent added
    # will have the least priority, and the last parent added will have the
    # highest priority.
    #
    # @param  Rend::Acl::Role|string       role
    # @param  Rend::Acl::Role|string|array parents
    # @uses   Rend::Acl::Role::Registry::add!()
    # @return Rend::Acl Provides a fluent interface
    def add_role!(role, parents = nil)
      role = Rend::Acl::Role.new(role) if role.is_a?(String)
      type_hint! Rend::Acl::Role, role, :is_required => true
      role_registry.add!(role, parents)
      self
    end

    # Returns the identified Role
    #
    # The role parameter can either be a Role or Role identifier.
    #
    # @param  Rend::Acl::Role|string role
    # @uses   Rend::Acl::Role::Registry::get!()
    # @return Rend::Acl::Role
    def role!(role)
      role_registry.get!(role)
    end

    # Returns true if and only if the Role exists in the registry
    #
    # The role parameter can either be a Role or a Role identifier.
    #
    # @param  Rend::Acl::Role|string role
    # @uses   Rend::Acl::Role::Registry::has?()
    # @return boolean
    def role?(role)
      role_registry.has?(role)
    end

    # Returns true if and only if role inherits from inherit
    #
    # Both parameters may be either a Role or a Role identifier. If
    # only_parents is true, then role must inherit directly from
    # inherit in order to return true. By default, this method looks
    # through the entire inheritance DAG to determine whether role
    # inherits from inherit through its ancestor Roles.
    #
    # @param  Rend::Acl::Role|string role
    # @param  Rend::Acl::Role|string inherit
    # @param  boolean                only_parents
    # @uses   Rend::Acl::Role::Registry::inherits?()
    # @return boolean
    def inherits_role?(role, inherit, only_parents = false)
      role_registry.inherits?(role, inherit, only_parents)
    end

    # Removes the Role from the registry
    #
    # The role parameter can either be a Role or a Role identifier.
    #
    # @param  Rend::Acl::Role|string role
    # @uses   Rend::Acl::Role::Registry::remove()
    # @return Rend::Acl Provides a fluent interface
    def remove_role!(role)
      role_registry.remove!(role)

      role_id = (role.class <= Rend::Acl::Role) ? role.id : role

      @_rules[:all_resources][:by_role_id].each do |role_id_current, rules|
        if role_id == role_id_current
          @_rules[:all_resources][:by_role_id].delete(role_id_current)
        end
      end

      @_rules[:by_resource_id].each do |resource_id_current, visitor|
        if visitor.has_key?(:by_role_id)
          visitor[:by_role_id].each do |role_id_current, rules|
            if role_id == role_id_current
              @_rules[:by_resource_id][resource_id_current][:by_role_id].delete(role_id_current)
            end
          end
        end
      end

      self
    end

    # Removes all Roles from the registry
    #
    # @uses   Rend::Acl::Role::Registry::remove_all!()
    # @return Rend::Acl Provides a fluent interface
    def remove_role_all!
      role_registry.remove_all!

      @_rules[:all_resources][:by_role_id].each do |role_id_current, rules|
        @_rules[:all_resources][:by_role_id].delete(role_id_current)
      end

      @_rules[:by_resource_id].each do |resource_id_current, visitor|
        visitor[:by_role_id].each do |role_id_current, rules|
          @_rules[:by_resource_id][resource_id_current][:by_role_id].delete(role_id_current)
        end
      end

      self
    end

    # Adds a Resource having an identifier unique to the ACL
    #
    # The parent parameter may be a reference to, or the string identifier for,
    # the existing Resource from which the newly added Resource will inherit.
    #
    # @param  Rend::Acl::Resource|string resource
    # @param  Rend::Acl::Resource|string parent
    # @throws Rend::Acl::Exception
    # @return Rend::Acl Provides a fluent interface
    def add_resource!(resource, parent = nil)
      resource = Rend::Acl::Resource.new(resource) if resource.is_a?(String)
      type_hint! Rend::Acl::Resource, resource, :is_required => true

      resource_id = resource.id

      raise Rend::Acl::Exception, "Resource id 'resource_id' already exists in the ACL" if resource?(resource_id)

      resource_parent = nil

      if parent
        begin
          resource_parent_id  = (parent.class <= Rend::Acl::Resource) ? parent.id : parent
          resource_parent     = resource!(resource_parent_id)
        rescue Rend::Acl::Exception
          raise Rend::Acl::Exception, "Parent Resource id 'resource_parent_id' does not exist"
        end
        @_resources[resource_parent_id][:children][resource_id] = resource
      end

      @_resources[resource_id] = { :instance => resource, :parent => resource_parent, :children => {} }
      self
    end

    # Returns the identified Resource
    #
    # The resource parameter can either be a Resource or a Resource identifier.
    #
    # @param  Rend::Acl::Resource|string resource
    # @throws Rend::Acl::Exception
    # @return Rend::Acl::Resource

    def resource!(resource)
      resource_id = (resource.class <= Rend::Acl::Resource) ? resource.id : resource.to_s
      raise Rend::Acl::Exception, "Resource 'resource_id' not found" unless resource?(resource)
      @_resources[resource_id][:instance]
    end

    # Returns true if and only if the Resource exists in the ACL
    #
    # The resource parameter can either be a Resource or a Resource identifier.
    #
    # @param  Rend::Acl::Resource|string resource
    # @return boolean
    def resource?(resource)
      resource_id = (resource.class <= Rend::Acl::Resource) ? resource.id : resource.to_s
      @_resources.keys.include?(resource_id)
    end

    # Returns true if and only if resource inherits from inherit
    #
    # Both parameters may be either a Resource or a Resource identifier. If
    # only_parent is true, then resource must inherit directly from
    # inherit in order to return true. By default, this method looks
    # through the entire inheritance tree to determine whether resource
    # inherits from inherit through its ancestor Resources.
    #
    # @param  Rend::Acl::Resource|string resource
    # @param  Rend::Acl::Resource|string inherit
    # @param  boolean                    only_parent
    # @throws Rend_Acl_Resource_Registry_Exception
    # @return boolean
    def inherits_resource?(resource, inherit, only_parent = false)
      resource_id = resource!(resource).id
      inherit_id  = resource!(inherit).id

      if @_resources[resource_id][:parent]
        parent_id = @_resources[resource_id][:parent].id
        return true   if inherit_id == parent_id
        return false  if only_parent
      else
        return false
      end

      while @_resources[parent_id][:parent]
        parent_id = @_resources[parent_id][:parent].id
        return true if inherit_id == parent_id
      end
      false
    end

    # Removes a Resource and all of its children
    #
    # The resource parameter can either be a Resource or a Resource identifier.
    #
    # @param  Rend::Acl::Resource|string resource
    # @throws Rend::Acl::Exception
    # @return Rend::Acl Provides a fluent interface
    def remove_resource!(resource)
      resource_id       = resource!(resource).id
      resources_removed = [resource_id]

      if resource_parent = @_resources[resource_id][:parent]
        @_resources[resource_parent.id][:children].delete(resource_id)
      end

      @_resources[resource_id][:children].each do |child_id, child|
        remove_resource!(child_id)
        resources_removed.push(child_id)
      end

      resources_removed.each do |resource_id_removed|
        @_rules[:by_resource_id].each do |resource_id_current, rules|
          if resource_id_removed == resource_id_current
            @_rules[:by_resource_id].delete(resource_id_current)
          end
        end
      end

      @_resources.delete(resource_id)

      self
    end

    # Removes all Resources
    #
    # @return Rend::Acl Provides a fluent interface
    def remove_resource_all!
      @_resources.each do |resource_id, resource|
        @_rules[:by_resource_id].each do |resource_id_current, rules|
          @_rules[:by_resource_id].delete(resource_id_current) if resource_id == resource_id_current
        end
      end

      @_resources = {}

      self
    end

    # Adds an "allow" rule to the ACL
    #
    # @param  Rend::Acl::Role|string|array     roles
    # @param  Rend::Acl::Resource|string|array resources
    # @param  string|array                     privileges
    # @param  Rend::Acl::Assertion             assertion
    # @uses   Rend::Acl::set_rule!()
    # @return Rend::Acl Provides a fluent interface
    def allow!(roles = nil, resources = nil, privileges = nil, assertion = nil)
      if roles.is_a?(Hash)
        options     = roles
        roles       = options.fetch(:role,      nil)
        resources   = options.fetch(:resource,  nil)
        privileges  = options.fetch(:privilege, nil)
        assertion   = options.fetch(:assertion, nil)
      end

      type_hint! Rend::Acl::Assertion, assertion

      set_rule!(OP_ADD, TYPE_ALLOW, roles, resources, privileges, assertion)
    end

    # Adds a "deny" rule to the ACL
    #
    # @param  Rend::Acl::Role|string|array     roles
    # @param  Rend::Acl::Resource|string|array resources
    # @param  string|array                     privileges
    # @param  Rend::Acl::Assertion             assertion
    # @uses   Rend::Acl::set_rule!()
    # @return Rend::Acl Provides a fluent interface
    def deny!(roles = nil, resources = nil, privileges = nil, assertion = nil)
      if roles.is_a?(Hash)
        options     = roles
        roles       = options.fetch(:role,      nil)
        resources   = options.fetch(:resource,  nil)
        privileges  = options.fetch(:privilege, nil)
        assertion   = options.fetch(:assertion, nil)
      end

      type_hint! Rend::Acl::Assertion, assertion

      set_rule!(OP_ADD, TYPE_DENY, roles, resources, privileges, assertion)
    end

    # Removes "allow" permissions from the ACL
    #
    # @param  Rend::Acl::Role|string|array     roles
    # @param  Rend::Acl::Resource|string|array resources
    # @param  string|array                     privileges
    # @uses   Rend::Acl::set_rule!()
    # @return Rend::Acl Provides a fluent interface
    def remove_allow!(roles = nil, resources = nil, privileges = nil, assertion = nil)
      if roles.is_a?(Hash)
        options     = roles
        roles       = options.fetch(:role,      nil)
        resources   = options.fetch(:resource,  nil)
        privileges  = options.fetch(:privilege, nil)
        assertion   = options.fetch(:assertion, nil)
      end

      set_rule!(OP_REMOVE, TYPE_ALLOW, roles, resources, privileges, assertion)
    end

    # Removes "deny" restrictions from the ACL
    #
    # @param  Rend::Acl::Role|string|array     roles
    # @param  Rend::Acl::Resource|string|array resources
    # @param  string|array                     privileges
    # @uses   Rend::Acl::set_rule!()
    # @return Rend::Acl Provides a fluent interface
    def remove_deny!(roles = nil, resources = nil, privileges = nil, assertion = nil)
      if roles.is_a?(Hash)
        options     = roles
        roles       = options.fetch(:role,      nil)
        resources   = options.fetch(:resource,  nil)
        privileges  = options.fetch(:privilege, nil)
        assertion   = options.fetch(:assertion, nil)
      end

      set_rule!(OP_REMOVE, TYPE_DENY, roles, resources, privileges, assertion)
    end

    # Performs operations on ACL rules
    #
    # The operation parameter may be either OP_ADD or OP_REMOVE, depending on whether the
    # user wants to add or remove a rule, respectively:
    #
    # OP_ADD specifics:
    #
    #      A rule is added that would allow one or more Roles access to [certain privileges
    #      upon] the specified Resource(s).
    #
    # OP_REMOVE specifics:
    #
    #      The rule is removed only in the context of the given Roles, Resources, and privileges.
    #      Existing rules to which the remove operation does not apply would remain in the
    #      ACL.
    #
    # The type parameter may be either TYPE_ALLOW or TYPE_DENY, depending on whether the
    # rule is intended to allow or deny permission, respectively.
    #
    # The roles and resources parameters may be references to, or the string identifiers for,
    # existing Resources/Roles, or they may be passed as arrays of these - mixing string identifiers
    # and objects is ok - to indicate the Resources and Roles to which the rule applies. If either
    # roles or resources is nil, then the rule applies to all Roles or all Resources, respectively.
    # Both may be nil in order to work with the default rule of the ACL.
    #
    # The privileges parameter may be used to further specify that the rule applies only
    # to certain privileges upon the Resource(s) in question. This may be specified to be a single
    # privilege with a string, and multiple privileges may be specified as an array of strings.
    #
    #
    # @param  string                            operation
    # @param  string                            type
    # @param  Rend::Acl::Role|string|array      roles
    # @param  Rend::Acl::Resource|string|array  resources
    # @param  string|array                      privileges
    # @param  Rend::Acl::Assert::Interface      assertion
    # @throws Rend::Acl::Exception
    # @uses   Rend::Acl::Role::Registry::get!()
    # @uses   Rend::Acl::get!()
    # @return Rend::Acl Provides a fluent interface
    def set_rule!(operation, type, roles = nil, resources = nil, privileges = nil, assertion = nil)
      type_hint! Rend::Acl::Assertion, assertion

      # ensure that the rule type is valid normalize input to uppercase
      type = type.upcase
      if type != TYPE_ALLOW && type != TYPE_DENY
        raise Rend::Acl::Exception, "Unsupported rule type must be either '#{TYPE_ALLOW}' or '#{TYPE_DENY}'"
      end

      # ensure that all specified Roles exist normalize input to array of Role objects or nil
      roles = Array(roles)
      roles << nil if roles.empty?
      roles = roles.reduce([]) {|seed, role| seed << (role ? role_registry.get!(role) : nil)}

      # ensure that all specified Resources exist normalize input to array of Resource objects or nil
      if resources
        resources = Array(resources)
        resources << nil if resources.empty?
        resources = resources.reduce([]) {|seed, resource| seed << (resource ? resource!(resource) : nil)}
      end

      # normalize privileges to array
      privileges = Array(privileges).compact

      case operation
      when OP_ADD     then _add_rule!(type, roles, resources, privileges, assertion)
      when OP_REMOVE  then _remove_rule!(type, roles, resources, privileges, assertion)
      else
        raise Rend::Acl::Exception, "Unsupported operation must be either '#{OP_ADD}' or '#{OP_REMOVE}'"
      end

      self
    end

    # Returns true if and only if the Role has access to the Resource
    #
    # The role and resource parameters may be references to, or the string identifiers for,
    # an existing Resource and Role combination.
    #
    # If either role or resource is nil, then the query applies to all Roles or all Resources,
    # respectively. Both may be nil to query whether the ACL has a "blacklist" rule
    # (allow everything to all). By default, Rend::Acl creates a "whitelist" rule (deny
    # everything to all), and this method would return false unless this default has
    # been overridden (i.e., by executing acl->allow()).
    #
    # If a privilege is not provided, then this method returns false if and only if the
    # Role is denied access to at least one privilege upon the Resource. In other words, this
    # method returns true if and only if the Role is allowed all privileges on the Resource.
    #
    # This method checks Role inheritance using a depth-first traversal of the Role registry.
    # The highest priority parent (i.e., the parent most recently added) is checked first,
    # and its respective parents are checked similarly before the lower-priority parents of
    # the Role are checked.
    #
    # @param  Rend::Acl::Role|string     role
    # @param  Rend::Acl::Resource|string resource
    # @param  string                     privilege
    # @uses   Rend::Acl::get!()
    # @uses   Rend::Acl::Role::Registry::get!()
    # @return boolean
    def allowed?(role = nil, resource = nil, privilege = nil)
      # reset role & resource to nil
      @_is_allowed_role       = nil
      @_is_allowed_resource   = nil
      @_is_allowed_privilege  = nil

      # Readability
      if role.is_a?(Hash)
        options   = role
        role      = options.fetch(:role,      nil)
        resource  = options.fetch(:resource,  nil)
        privilege = options.fetch(:privilege, nil)
      end

      if role
        # keep track of originally called role
        @_is_allowed_role = role
        role = role_registry.get!(role)
        @_is_allowed_role = role unless @_is_allowed_role.class <= Rend::Acl::Role
      end

      if resource
        # keep track of originally called resource
        @_is_allowed_resource = resource
        resource = resource!(resource)
        unless @_is_allowed_resource.class <= Rend::Acl::Resource
          @_is_allowed_resource = resource
        end
      end


      if privilege.nil?
        # query on all privileges
        loop do # loop terminates at :all_resources pseudo-parent
          # depth-first search on role if it is not :all_roles pseudo-parent
          if !role.nil? && !(result = _role_dfs_all_privileges(role, resource)).nil?
            return result
          end


          # look for rule on :all_roles psuedo-parent
          rules = _rules(resource, nil)
          if rules
            rules[:by_privilege_id].each do |priv, rule|
              rule_type_one_privilege = _rule_type(resource, nil, priv)
              return false if rule_type_one_privilege == TYPE_DENY
            end
            rule_type_one_privilege = _rule_type(resource, nil, nil)
            return rule_type_one_privilege == TYPE_ALLOW if rule_type_one_privilege
          end

          # try next Resource
          resource = @_resources[resource.id][:parent]
        end
      else
        @_is_allowed_privilege = privilege
        # query on one privilege
        loop do # loop terminates at :all_resources pseudo-parent
          # depth-first search on role if it is not :all_roles pseudo-parent
          if !role.nil? && !(result = _role_dfs_one_privilege(role, resource, privilege)).nil?
            return result
          end

          # look for rule on 'allRoles' pseudo-parent
          if nil != (rule_type = _rule_type(resource, nil, privilege))
            return TYPE_ALLOW == rule_type
          elsif nil != (rule_type_all_privileges = _rule_type(resource, nil, nil))
            return TYPE_ALLOW == rule_type_all_privileges
          end

          # try next Resource
          resource = @_resources[resource.id][:parent]
        end
      end
    end

    # Returns the Role registry for this ACL
    #
    # If no Role registry has been created yet, a new default Role registry
    # is created and returned.
    #
    # @return Rend::Acl::Role::Registry
    def role_registry
      @_role_registry ||= Rend::Acl::Role::Registry.new
    end

    # Returns an array of registered roles.
    #
    # Note that this method does not return instances of registered roles,
    # but only the role identifiers.
    #
    # @return array of registered roles
    def roles
      role_registry.roles.keys
    end

    # @return array of registered resources
    def resources
      @_resources.keys
    end

    # == PROTECTED ================================================================================

    protected

    # =============================================================================================

    # Performs a depth-first search of the Role DAG, starting at role, in order to find a rule
    # allowing/denying role access to all privileges upon resource
    #
    # This method returns true if a rule is found and allows access. If a rule exists and denies access,
    # then this method returns false. If no applicable rule is found, then this method returns nil.
    #
    # @param  Rend::Acl::Role     role
    # @param  Rend::Acl::Resource resource
    # @return boolean|nil
    def _role_dfs_all_privileges(role, resource = nil)
      type_hint! Rend::Acl::Role,     role, :is_required => true
      type_hint! Rend::Acl::Resource, resource

      dfs = {:visited => {}, :stack => []}

      result = _role_dfs_visit_all_privileges(role, resource, dfs)
      return result unless result.nil?

      while role = dfs[:stack].pop
        unless dfs[:visited].has_key?(role.id)
          result = _role_dfs_visit_all_privileges(role, resource, dfs)
          return result unless result.nil?
        end
      end
      nil
    end

    # Visits an role in order to look for a rule allowing/denying role access to all privileges upon resource
    #
    # This method returns true if a rule is found and allows access. If a rule exists and denies access,
    # then this method returns false. If no applicable rule is found, then this method returns nil.
    #
    # This method is used by the internal depth-first search algorithm and may modify the DFS data structure.
    #
    # @param  Rend::Acl::Role     role
    # @param  Rend::Acl::Resource resource
    # @param  array          dfs
    # @return boolean|nil
    # @throws Rend::Acl::Exception
    def _role_dfs_visit_all_privileges(role, resource = nil, dfs = nil)
      type_hint! Rend::Acl::Role,      role, :is_required => true
      type_hint! Rend::Acl::Resource,  resource
      raise Rend::Acl::Exception, 'dfs parameter may not be nil' if dfs.nil?

      if rules = _rules(resource, role)
        rules[:by_privilege_id].each do |privilege, rule|
          rule_type_one_privilege = _rule_type(resource, role, privilege)
          return false if rule_type_one_privilege == TYPE_DENY
        end
        rule_type_all_privileges = _rule_type(resource, role, nil)
        return rule_type_all_privileges == TYPE_ALLOW unless rule_type_all_privileges.nil?
      end

      dfs[:visited][role.id] = true
      role_registry.parents(role).each do |role_parent_id, role_parent|
        dfs[:stack].push(role_parent)
      end
      nil
    end

    # Performs a depth-first search of the Role DAG, starting at role, in order to find a rule
    # allowing/denying role access to a privilege upon resource
    #
    # This method returns true if a rule is found and allows access. If a rule exists and denies access,
    # then this method returns false. If no applicable rule is found, then this method returns nil.
    #
    # @param  Rend::Acl::Role     role
    # @param  Rend::Acl::Resource resource
    # @param  string              privilege
    # @return boolean|nil
    # @throws Rend::Acl::Exception
    def _role_dfs_one_privilege(role, resource = nil, privilege = nil)
      type_hint! Rend::Acl::Role,      role, :is_required => true
      type_hint! Rend::Acl::Resource,  resource
      raise Rend::Acl::Exception, 'privilege parameter may not be nil' if privilege.nil?

      dfs = {:visited => {}, :stack => []}

      result = _role_dfs_visit_one_privilege(role, resource, privilege, dfs)
      return result unless result.nil?

      while role = dfs[:stack].pop
        unless dfs[:visited].has_key?(role.id)
          result = _role_dfs_visit_one_privilege(role, resource, privilege, dfs)
          return result unless result.nil?
        end
      end
      nil
    end

    # Visits an role in order to look for a rule allowing/denying role access to a privilege upon resource
    #
    # This method returns true if a rule is found and allows access. If a rule exists and denies access,
    # then this method returns false. If no applicable rule is found, then this method returns nil.
    #
    # This method is used by the internal depth-first search algorithm and may modify the DFS data structure.
    #
    # @param  Rend::Acl::Role     role
    # @param  Rend::Acl::Resource resource
    # @param  string              privilege
    # @param  array               dfs
    # @return boolean|nil
    # @throws Rend::Acl::Exception
    def _role_dfs_visit_one_privilege(role, resource = nil, privilege = nil, dfs = nil)
      type_hint! Rend::Acl::Role,      role, :is_required => true
      type_hint! Rend::Acl::Resource,  resource
      raise Rend::Acl::Exception, 'privilege parameter may not be nil'  if privilege.nil?
      raise Rend::Acl::Exception, 'dfs parameter may not be nil'        if dfs.nil?


      if rule_type_one_privilege = _rule_type(resource, role, privilege)
        return rule_type_one_privilege == TYPE_ALLOW
      end

      if rule_type_all_privileges = _rule_type(resource, role, nil)
        return rule_type_all_privileges == TYPE_ALLOW
      end

      dfs[:visited][role.id] = true
      role_registry.parents(role).each do |role_parent_id, role_parent|
        dfs[:stack].push(role_parent)
      end
      nil
    end

    # Returns the rule type associated with the specified Resource, Role, and privilege
    # combination.
    #
    # If a rule does not exist then this method returns nil. Otherwise, the
    # rule type applies and is returned as either TYPE_ALLOW or TYPE_DENY.
    #
    # If resource or role is nil, then this means that the rule must apply to
    # all Resources or Roles, respectively.
    #
    # If privilege is nil, then the rule must apply to all privileges.
    #
    # If all three parameters are nil, then the default ACL rule type is returned,
    # based on whether its assertion method passes.
    #
    # @param  Rend::Acl::Resource  resource
    # @param  Rend::Acl::Role      role
    # @param  string                  privilege
    # @return string|nil
    def _rule_type(resource = nil, role = nil, privilege = nil)
      type_hint! Rend::Acl::Resource,  resource
      type_hint! Rend::Acl::Role,      role

      # get the rules for the resource and role
      return nil unless rules = _rules(resource, role)

      # follow privilege
      if privilege.nil?
        if rules.has_key?(:all_privileges)
          rule = rules[:all_privileges]
        else
          return nil
        end
      elsif !rules || !rules[:by_privilege_id].has_key?(privilege)
        return nil
      else
        rule = rules[:by_privilege_id][privilege]
      end

      # Check assertion first
      assertion_passed = nil
      if rule[:assertion]
          args = {
            :acl        => self,
            :role       => @_is_allowed_role.is_a?(Rend::Acl::Role)         ? @_is_allowed_role     : role,
            :resource   => @_is_allowed_resource.is_a?(Rend::Acl::Resource) ? @_is_allowed_resource : resource,
            :privilege  => @_is_allowed_privilege
          }
          assertion_passed = rule[:assertion].pass?(args[:acl], args[:role], args[:resource], args[:privilege])
      end

      if rule[:assertion].nil? || assertion_passed == true
        rule[:type]
      elsif resource != nil || role != nil || privilege != nil
        nil
      elsif rule[:type] == TYPE_ALLOW
        TYPE_DENY
      else
        TYPE_ALLOW
      end
    end


    # Returns the rules associated with a Resource and a Role, or nil if no such rules exist
    #
    # If either resource or role is nil, this means that the rules returned are for all Resources or all Roles,
    # respectively. Both can be nil to return the default rule set for all Resources and all Roles.
    #
    # If the create parameter is true, then a rule set is first created and then returned to the caller.
    #
    # @param  Rend::Acl::Resource resource
    # @param  Rend::Acl::Role     role
    # @param  boolean             create
    # @return array|nil
    def _rules(resource = nil, role = nil, create = false)
      type_hint! Rend::Acl::Resource, resource
      type_hint! Rend::Acl::Role,     role

      if resource.nil?
        visitor = @_rules[:all_resources]
      else
        if !@_rules[:by_resource_id].has_key?(resource.id)
          return nil unless create
          @_rules[:by_resource_id][resource.id] = {}
        end
        visitor = @_rules[:by_resource_id][resource.id]
      end

      if role.nil?
        if !visitor.has_key?(:all_roles)
          return nil unless create
          visitor[:all_roles] = { :by_privilege_id => {} }
        end
        return visitor[:all_roles]
      end

      visitor[:by_role_id] = {} unless visitor.has_key?(:by_role_id)

      unless visitor[:by_role_id].has_key?(role.id)
        return nil unless create
        visitor[:by_role_id][role.id] = {
          :by_privilege_id => {},
          :all_privileges => {:type => nil}
        }
      end
      visitor[:by_role_id][role.id]
    end

    def _add_rule!(type, roles, resources, privileges, assertion)
      if resources
        # this block will iterate the provided resources
        resources.each do |resource|
          roles.each do |role|
            rules = _rules(resource, role, true)
            if privileges.empty?
              rules[:all_privileges]  = {:type => type, :assertion => assertion}
              rules[:by_privilege_id] = {} unless rules.has_key?(:by_privilege_id)
            else
              privileges.each do |privilege|
                rules[:by_privilege_id][privilege] = {:type => type, :assertion => assertion}
              end
            end
          end
        end
      else
        # this block will apply to all resources in a global rule
        roles.each do |role|
          rules = _rules(nil, role, true)
          if privileges.empty?
            rules[:all_privileges] = {:type => type, :assertion => assertion}
          else
            privileges.each do |privilege|
              rules[:by_privilege_id][privilege] = {:type => type, :assertion => assertion}
            end
          end
        end
      end
    end

    def _remove_rule!(type, roles, resources, privileges, assertion)
      if resources
        # this block will iterate the provided resources
        resources.each do |resource|
          roles.each do |role|
            rules = _rules(resource, role)
            next if rules.nil?
            if privileges.empty?
              if resource.nil? && role.nil?
                if rules[:all_privileges][:type] == type
                  rules.replace({
                    :all_privileges => {
                      :type       => TYPE_DENY,
                      :assertion  => nil
                    },
                    :by_privilege_id  => {}
                  })
                end
                next
              end
              rules.delete(:all_privileges) if rules[:all_privileges][:type] == type
            else
              privileges.each do |privilege|
                if rules[:by_privilege_id].has_key?(privilege) && rules[:by_privilege_id][privilege][:type] == type
                  rules[:by_privilege_id].delete(privilege)
                end
              end
            end
          end
        end
      else
        all_resources = @_resources.values.reduce([]) {|seed, r_target| seed << r_target[:instance]}

        # this block will apply to all resources in a global rule
        roles.each do |role|

          # since nil (all resources) was passed to this set_role!() call, we need
          # clean up all the rules for the global all_resources, as well as the indivually
          # set resources (per privilege as well)
          [nil].concat(all_resources).each do |resource|
            rules = _rules(resource, role, true)
            next if rules.nil?
            if privileges.empty?
              if role.nil?
                if rules[:all_privileges][:type] == type
                  rules.replace(:all_privileges => {:type => TYPE_DENY, :assertion => nil}, :by_privilege_id => {})
                end
                next
              end

              if rules[:all_privileges].has_key?(:type) && rules[:all_privileges][:type] == type
                rules.delete(:all_privileges)
              end
            else
              privileges.each do |privilege|
                if rules[:by_privilege_id].has_key?(privilege) && rules[:by_privilege_id][privilege][:type] == type
                  rules[:by_privilege_id].delete(privilege)
                end
              end
            end
          end
        end
      end
    end

  end
end