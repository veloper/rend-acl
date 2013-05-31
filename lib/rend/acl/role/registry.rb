require 'rend/acl/role/registry/exception'
module Rend
  class Acl
    class Role
      class Registry
        include Rend::Core::Helpers::Php

        # Internal Role registry data storage
        # @var hash
        attr_accessor :roles

        def initialize
          self.roles = {}
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
        # @param  Rend::Acl::Role              role
        # @param  Rend::Acl::Role|string|array parents
        # @throws Rend::Acl::Role::Registry::Exception
        # @return Rend::Acl::Role::Registry Provides a fluent interface
        def add!(role, parents = nil)
          type_hint! Rend::Acl::Role, role, :is_required => true

          role_id = role.id
          raise Exception, "Role id 'role_id' already exists in the registry" if has?(role_id)

          role_parents = {}

          if parents
            Array(parents).each do |parent|
              begin
                role_parent_id  = (parent.class <= Rend::Acl::Role) ? parent.id : parent
                role_parent     = get!(role_parent_id)
              rescue Exception
                raise Exception, "Parent Role id 'role_parent_id' does not exist"
              end
              role_parents[role_parent_id] = role_parent
              roles[role_parent_id][:children][role_id] = role
              # roles[role_parent_id][:instance].children[role_id] = role # future
            end
          end

          # role.parents = role_parents -- future

          roles[role_id] = {
            :instance   => role,
            :parents    => role_parents,
            :children   => {}
          }

          self
        end


        # Returns the identified Role
        #
        # The role parameter can either be a Role or a Role identifier.
        #
        # @param  Rend::Acl::Role|string role
        # @throws Rend::Acl::Role::Registry::Exception
        # @return Rend::Acl::Role
        def get!(role)
          raise Exception, "Role 'role_id' not found" unless has?(role)
          role_id = (role.class <= Rend::Acl::Role) ? role.id : role.to_s
          roles[role_id][:instance]
        end


        # Returns true if and only if the Role exists in the registry
        #
        # The role parameter can either be a Role or a Role identifier.
        #
        # @param  Rend::Acl::Role|string role
        # @return boolean
        def has?(role)
          role_id = (role.class <= Rend::Acl::Role) ? role.id : role.to_s
          roles.has_key?(role_id)
        end


        # Returns an array of an existing Role's parents
        #
        # The array keys are the identifiers of the parent Roles, and the values are
        # the parent Role instances. The parent Roles are ordered in this array by
        # ascending priority. The highest priority parent Role, last in the array,
        # corresponds with the parent Role most recently added.
        #
        # If the Role does not have any parents, then an empty array is returned.
        #
        # @param  Rend::Acl::Role|string role
        # @uses   Rend::Acl::Role::Registry::get!
        # @return array
        def parents(role)
          roles[get!(role).id][:parents]
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
        # @param  boolean                        only_parents
        # @throws Rend::Acl::Role::Registry::Exception
        # @return boolean
        def inherits?(role, inherit, only_parents = false)
          role_id     = get!(role).id
          inherit_id  = get!(inherit).id
          inherits    = roles[role_id][:parents].has_key?(inherit_id)

          return inherits if inherits || only_parents

          roles[role_id][:parents].each do |parent_id, parent|
              return true if inherits?(parent_id, inherit_id)
          end
          false
        end


        # Removes the Role from the registry
        #
        # The role parameter can either be a Role or a Role identifier.
        #
        # @param  Rend::Acl::Role|string role
        # @throws Rend::Acl::Role::Registry::Exception
        # @return Rend::Acl::Role::Registry Provides a fluent interface
        def remove!(role)
          role_id = get!(role).id

          roles[role_id][:children].each do |child_id, child|
            roles[child_id][:parents].delete(role_id)
          end

          roles[role_id][:parents].each do |parent_id, parent|
            roles[parent_id][:children][role_id]
          end

          roles.delete(role_id)

          self
        end

        def remove_all!
          roles.replace({})
          self
        end

      end
    end
  end
end