require 'test/unit'
require 'rend/acl'

class AclTest < Test::Unit::TestCase

  def setup
    @acl = Rend::Acl.new
  end

  def test_storing_acl_data_for_persistence_with_marshal
    assert_use_case_1 Marshal.load( Marshal.dump(use_case_1) )
  end

  def test_storing_acl_data_for_persistence_with_yaml
    require 'yaml'
    assert_use_case_1 YAML.load( YAML.dump(use_case_1) )
  end

  def test_use_case_1
    assert_use_case_1(use_case_1)
  end

  def test_add_with_single_role_object_via_arguments
    @acl.add! Rend::Acl::Role.new("editor")
    assert @acl.role? "editor"
  end

  def test_add_with_single_role_object_using_inheritance_object_via_arguments
    @acl.add! role_guest  = Rend::Acl::Role.new("guest")
    @acl.add! role_editor = Rend::Acl::Role.new("editor"), role_guest
    assert @acl.inherits_role? "editor", role_guest
  end

  def test_add_with_single_role_object_using_inheritance_string_via_arguments
    @acl.add! Rend::Acl::Role.new("guest")
    @acl.add! Rend::Acl::Role.new("editor"), "guest"
    assert @acl.inherits_role? "editor", "guest"
  end

  def test_add_with_single_role_object_via_hash
    @acl.add! :role => "editor"
    assert @acl.role? "editor"
  end

  def test_add_with_single_role_object_using_inheritance_object_via_hash
    @acl.add! role_guest  = Rend::Acl::Role.new("guest")
    @acl.add! :role => {Rend::Acl::Role.new("editor") => role_guest}
    assert @acl.inherits_role? "editor", role_guest
  end

  def test_add_with_single_role_string_using_inheritance_object_via_hash
    @acl.add! role_guest  = Rend::Acl::Role.new("guest")
    @acl.add! :role => {"editor" => role_guest}
    assert @acl.inherits_role? "editor", role_guest
  end

  def test_add_with_single_role_string_using_inheritance_string_via_hash
    @acl.add! Rend::Acl::Role.new("guest")
    @acl.add! :role => {"editor" => "guest"}
    assert @acl.inherits_role? "editor", "guest"
  end

  def test_add_with_multiple_role_strings_via_hash
    @acl.add! :role => ['city', 'building', 'room']
    assert @acl.role? "city"
    assert @acl.role? "building"
    assert @acl.role? "room"
  end

  def test_add_with_multiple_role_strings_using_inheritance_strings_via_hash
    @acl.add! :role => ['city', {'building' => 'city'}, {'room' => 'building'}, 'user']
    assert @acl.role? "city"
    assert @acl.role? "building"
    assert @acl.role? "room"
    assert @acl.role? "user"
    assert @acl.inherits_role? "building", "city"
    assert @acl.inherits_role? "room", "building"
  end

  def test_adding_with_add!
    # Simplify adding roles and resources
    #
    # - Roles
    #   - Arguments
    #     .add! Rend::Acl::Role.new("editor")                                 # Single
    #     .add! Rend::Acl::Role.new("editor"), 'guest'                        # Single w/ Inheritance
    #   - Options Hash
    #     .add! :role => 'editor'                                             # Single
    #     .add! :role => {'editor' => 'guest'}                                # Single w/ Inheritance
    #     .add! :role => ['guest', 'editor']                                  # Multiple
    #     .add! :role => ['guest', 'contributor', {'editor' => 'guest'}]      # Multiple w/ Inheritance
    # - Resources
    #   - Arguments
    #     .add! Rend::Acl::Resource.new("city")                               # Single
    #     .add! Rend::Acl::Resource.new("building"), 'city'                   # Single w/ Inheritance
    #     .add! Rend::Acl::Resource.new("building"), ['city', 'building']     # Single w/ Multiple Inheritance
    #   - Options Hash
    #     .add! :resource => 'city'                                           # Single
    #     .add! :resource => {'building' => 'city'}                           # Single w/ Inheritance
    #     .add! :resource => ['city', 'building']                             # Multiple
    #     .add! :resource => ['city', 'building', {'building' => 'city'}]     # Multiple w/ Inheritance
    # - Mixed Roles & Resources
    #     .add! :role => ['guest', {'editor' => 'guest'}], :resource => ['city', {'building' => 'city'}]
    #
  end

  # ==== Orignal Zend_Acl Tests Below

  # Ensures that basic addition and retrieval of a single Role works
  def test_role_registry_add_and_get_one
    role_guest = Rend::Acl::Role.new('guest')
    @acl.add_role!(role_guest)
    assert_equal role_guest, @acl.role!(role_guest.id)
  end

  # Ensures that basic addition and retrieval of a single Resource works
  def test_role_add_and_get_one_by_string
    role = @acl.add_role!('area').role!('area')
    assert_kind_of Rend::Acl::Role, role
    assert_equal 'area', role.id
  end

  # # Ensures that basic removal of a single Role works
  def test_role_registry_remove_one
    role_guest = Rend::Acl::Role.new('guest')
    @acl.add_role!(role_guest).remove_role!(role_guest)
    assert_equal false, @acl.role?(role_guest)
  end

  # Ensures that an exception is thrown when a non-existent Role is specified for removal
  def test_role_registry_remove_one_non_existent
    assert_raises Rend::Acl::Role::Registry::Exception do
      @acl.remove_role!('nonexistent')
      flunk('Expected Rend::Acl::Role::Registry::Exception not thrown upon removing a non-existent Role')
    end
  end

  # # Ensures that removal of all Roles works
  def test_role_registry_remove_all
    role_guest = Rend::Acl::Role.new('guest')
    @acl.add_role!(role_guest).remove_role_all!
    assert_equal false, @acl.role?(role_guest)
  end

  # Ensures that an exception is thrown when a non-existent Role is specified as a parent upon Role addition
  def test_role_registry_add_inherits_non_existent
    assert_raises Rend::Acl::Role::Registry::Exception do
      @acl.add_role!(Rend::Acl::Role.new('guest'), 'nonexistent')
      flunk('Expected Rend::Acl::Role::Registry::Exception not thrown upon specifying a non-existent parent')
    end
  end

  # Ensures that an exception is thrown when a non-existent Role is specified to each parameter of inherits
  def test_role_registry_inherits_non_existent
    role_guest = Rend::Acl::Role.new('guest')
    @acl.add_role!(role_guest)
    assert_raises Rend::Acl::Role::Registry::Exception do
      @acl.inherits_role?('nonexistent', role_guest)
      flunk('Expected Rend::Acl::Role::Registry::Exception not thrown upon specifying a non-existent child Role')
    end
    assert_raises Rend::Acl::Role::Registry::Exception do
      @acl.inherits_role?(role_guest, 'nonexistent')
      flunk('Expected Rend::Acl::Role::Registry::Exception not thrown upon specifying a non-existent parent Role')
    end
  end

  # Tests basic Role inheritance
  def test_role_registry_inherits
    role_guest  = Rend::Acl::Role.new('guest')
    role_member = Rend::Acl::Role.new('member')
    role_editor = Rend::Acl::Role.new('editor')

    role_registry = Rend::Acl::Role::Registry.new
    role_registry.add!(role_guest)
    role_registry.add!(role_member, role_guest.id)
    role_registry.add!(role_editor, role_member)

    assert_equal 0, role_registry.parents(role_guest).length

    role_member_parents = role_registry.parents(role_member)
    assert_equal 1,     role_member_parents.length
    assert_equal true,  role_member_parents.has_key?('guest')

    role_editor_parents = role_registry.parents(role_editor)
    assert_equal 1,     role_editor_parents.length
    assert_equal true,  role_editor_parents.has_key?('member')
    assert_equal true,  role_registry.inherits?(role_member, role_guest, true)
    assert_equal true,  role_registry.inherits?(role_editor, role_member, true)
    assert_equal true,  role_registry.inherits?(role_editor, role_guest)
    assert_equal false, role_registry.inherits?(role_guest, role_member)
    assert_equal false, role_registry.inherits?(role_member, role_editor)
    assert_equal false, role_registry.inherits?(role_guest, role_editor)

    role_registry.remove!(role_member)
    assert_equal 0,     role_registry.parents(role_editor).length
    assert_equal false, role_registry.inherits?(role_editor, role_guest)
  end

  # Tests basic Role multiple inheritance
  def test_role_registry_inherits_multiple
    role_parent0 = Rend::Acl::Role.new('parent0')
    role_parent1 = Rend::Acl::Role.new('parent1')
    role_child   = Rend::Acl::Role.new('child')

    role_registry = Rend::Acl::Role::Registry.new
    role_registry.add!(role_parent0)
    role_registry.add!(role_parent1)
    role_registry.add!(role_child, [role_parent0, role_parent1])

    role_child_parents = role_registry.parents(role_child)
    assert_equal 2,     role_child_parents.length
    role_child_parents.each_with_index do |(role_parent_id, role_parent), i|
      assert_equal "parent#{i}", role_parent_id
    end
    assert_equal true,  role_registry.inherits?(role_child, role_parent0)
    assert_equal true,  role_registry.inherits?(role_child, role_parent1)

    role_registry.remove!(role_parent0)
    role_child_parents = role_registry.parents(role_child)
    assert_equal 1,     role_child_parents.length
    assert_equal true,  role_child_parents.has_key?('parent1')
    assert_equal true,  role_registry.inherits?(role_child, role_parent1)
  end

  # Ensures that the same Role cannot be registered more than once to the registry
  def test_role_registry_duplicate
    role_guest    = Rend::Acl::Role.new('guest')
    role_registry = Rend::Acl::Role::Registry.new
    assert_raises Rend::Acl::Role::Registry::Exception do
      role_registry.add!(role_guest).add!(role_guest)
      flunk('Expected exception not thrown upon adding same Role twice')
    end
  end

  # Ensures that two Roles having the same ID cannot be registered
  def test_role_registry_duplicate_id
    role_guest1   = Rend::Acl::Role.new('guest')
    role_guest2   = Rend::Acl::Role.new('guest')
    role_registry = Rend::Acl::Role::Registry.new
    assert_raises Rend::Acl::Role::Registry::Exception do
      role_registry.add!(role_guest1).add!(role_guest2)
      flunk('Expected exception not thrown upon adding same Role twice')
    end
  end

  # Ensures that basic addition and retrieval of a single Resource works
  def test_resource_add_and_get_one
    resource_area = Rend::Acl::Resource.new('area')
    @acl.add_resource!(resource_area)

    resource = @acl.resource!(resource_area.id)
    assert_equal resource_area, resource

    resource = @acl.resource!(resource_area)
    assert_equal resource_area, resource
  end

  # Ensures that basic addition and retrieval of a single Resource works
  def test_resource_add_and_get_one_by_string
    @acl.add_resource!('area')

    resource = @acl.resource!('area')
    assert_kind_of Rend::Acl::Resource, resource
    assert_equal 'area', resource.id
  end

  # Ensures that basic removal of a single Resource works
  def test_resource_remove_one
    resource_area = Rend::Acl::Resource.new('area')
    @acl.add_resource!(resource_area).remove_resource!(resource_area)
    assert_equal false, @acl.resource?(resource_area)
  end

  # Ensures that an exception is thrown when a non-existent Resource is specified for removal
  def test_resource_remove_one_non_existent
    assert_raises Rend::Acl::Exception do
      @acl.remove_resource!('nonexistent')
      flunk('Expected Rend::Acl::Exception not thrown upon removing a non-existent Resource')
    end
  end

  # Ensures that removal of all Resources works
  def test_resource_remove_all
    resource_area = Rend::Acl::Resource.new('area')
    @acl.add_resource!(resource_area).remove_resource_all!
    assert_equal false, @acl.resource?(resource_area)
  end

  # Ensures that an exception is thrown when a non-existent Resource is specified as a parent upon Resource addition
  def test_resource_add_inherits_non_existent
    assert_raises Rend::Acl::Exception do
      @acl.add_resource!(Rend::Acl::Resource.new('area'), 'nonexistent')
      flunk('Expected Rend::Acl::Exception not thrown upon specifying a non-existent parent')
    end
  end

  # Ensures that an exception is thrown when a non-existent Resource is specified to each parameter of inherits
  def test_resource_inherits_non_existent
    resource_area = Rend::Acl::Resource.new('area')
    @acl.add_resource!(resource_area)
    assert_raises Rend::Acl::Exception do
      @acl.inherits_resource?('nonexistent', resource_area)
      flunk('Expected Rend::Acl::Exception not thrown upon specifying a non-existent child Resource')
    end
    assert_raises Rend::Acl::Exception do
      @acl.inherits_resource?(resource_area, 'nonexistent')
      flunk('Expected Rend::Acl::Exception not thrown upon specifying a non-existent parent Resource')
    end
  end

  # Tests basic Resource inheritance
  def test_resource_inherits
    resource_city     = Rend::Acl::Resource.new('city')
    resource_building = Rend::Acl::Resource.new('building')
    resource_room     = Rend::Acl::Resource.new('room')

    @acl.add_resource!(resource_city)
    @acl.add_resource!(resource_building, resource_city.id)
    @acl.add_resource!(resource_room,     resource_building)

    assert_equal true,  @acl.inherits_resource?(resource_building, resource_city, true)
    assert_equal true,  @acl.inherits_resource?(resource_room, resource_building, true)
    assert_equal true,  @acl.inherits_resource?(resource_room, resource_city)
    assert_equal false, @acl.inherits_resource?(resource_city, resource_building)
    assert_equal false, @acl.inherits_resource?(resource_building, resource_room)
    assert_equal false, @acl.inherits_resource?(resource_city, resource_room)

    @acl.remove_resource!(resource_building)
    assert_equal false, @acl.resource?(resource_room)
  end

  # Ensures that the same Resource cannot be added more than once
  def test_resource_duplicate
    assert_raises Rend::Acl::Exception do
      resource_area = Rend::Acl::Resource.new('area')
      @acl.add_resource!(resource_area)
      @acl.add_resource!(resource_area)
      flunk('Expected exception not thrown upon adding same Resource twice')
    end
  end

  # Ensures that two Resources having the same ID cannot be added
  def test_resource_duplicate_id
    assert_raises Rend::Acl::Exception do
      resource_area1 = Rend::Acl::Resource.new('area')
      resource_area2 = Rend::Acl::Resource.new('area')
      @acl.add_resource!(resource_area1)
      @acl.add_resource!(resource_area2)
      flunk('Expected exception not thrown upon adding two Resources with same ID')
    end
  end

  # Ensures that an exception is thrown when a non-existent Role and Resource parameters are specified to is_allowed
  def test_is_allowed_non_existent
    assert_raises Rend::Acl::Role::Registry::Exception do
      @acl.allowed?('nonexistent')
      flunk('Expected Rend::Acl::Role::Registry::Exception not thrown upon non-existent Role')
    end
    assert_raises Rend::Acl::Exception do
      @acl.allowed?(nil, 'nonexistent')
      flunk('Expected Rend::Acl::Exception not thrown upon non-existent Resource')
    end
  end

  # Ensures that by default, Zend_Acl denies access to everything by all
  def test_default_deny
    assert_equal false, @acl.allowed?
  end

  # Ensures that ACL-wide rules (all Roles, Resources, and privileges) work properly
  def test_default_rule_set
    @acl.allow!
    assert_equal true, @acl.allowed?
    @acl.deny!
    assert_equal false, @acl.allowed?
  end

  # Ensures that by default, Zend_Acl denies access to a privilege on anything by all
  def test_default_privilege_deny
    assert_equal false, @acl.allowed?(nil, nil, 'some_privilege')
  end

  # Ensures that ACL-wide rules apply to privileges
  def test_default_rule_set_privilege
    @acl.allow!
    assert_equal true, @acl.allowed?(nil, nil, 'some_privilege')
    @acl.deny!
    assert_equal false, @acl.allowed?(nil, nil, 'some_privilege')
  end

  # Ensures that a privilege allowed for all Roles upon all Resources works properly
  def test_privilege_allow
    @acl.allow!(nil, nil, 'some_privilege')
    assert_equal true, @acl.allowed?(nil, nil, 'some_privilege')
  end

  # Ensures that a privilege denied for all Roles upon all Resources works properly
  def test_privilege_deny
    @acl.allow!
    @acl.deny!(nil, nil, 'some_privilege')
    assert_equal false, @acl.allowed?(nil, nil, 'some_privilege')
  end

  # Ensures that multiple privileges work properly
  def test_privileges
    @acl.allow!(nil, nil, ['p1', 'p2', 'p3'])
    assert_equal true,  @acl.allowed?(nil, nil, 'p1')
    assert_equal true,  @acl.allowed?(nil, nil, 'p2')
    assert_equal true,  @acl.allowed?(nil, nil, 'p3')
    assert_equal false, @acl.allowed?(nil, nil, 'p4')

    @acl.deny!(nil, nil, 'p1')
    assert_equal false, @acl.allowed?(nil, nil, 'p1')

    @acl.deny!(nil, nil, ['p2', 'p3'])
    assert_equal false, @acl.allowed?(nil, nil, 'p2')
    assert_equal false, @acl.allowed?(nil, nil, 'p3')
  end

  # # [NOT IMPLEMENTED YET] Ensures that assertions on privileges work properly
  # def test_privilege_assert
  #   @acl.allow!(nil, nil, 'some_privilege', Rend::Acl::Mock_assertion.new(true))
  #   assert_equal true, @acl.allowed?(nil, nil, 'some_privilege')
  #   @acl.allow!(nil, nil, 'some_privilege', Rend::Acl::Mock_assertion.new(false))
  #   assert_equal false, @acl.allowed?(nil, nil, 'some_privilege')
  # end

  # Ensures that by default, Zend_Acl denies access to everything for a particular Role
  def test_role_default_deny
    role_guest = Rend::Acl::Role.new('guest')
    @acl.add_role!(role_guest)
    assert_equal false, @acl.allowed?(role_guest)
  end

  # Ensures that ACL-wide rules (all Resources and privileges) work properly for a particular Role
  def test_role_default_rule_set
    role_guest = Rend::Acl::Role.new('guest')
    @acl.add_role!(role_guest)
    @acl.allow!(role_guest)
    assert_equal true, @acl.allowed?(role_guest)
    @acl.deny!(role_guest)
    assert_equal false, @acl.allowed?(role_guest)
  end

  # Ensures that by default, Zend_Acl denies access to a privilege on anything for a particular Role
  def test_role_default_privilege_deny
    role_guest = Rend::Acl::Role.new('guest')
    @acl.add_role!(role_guest)
    assert_equal false, @acl.allowed?(role_guest, nil, 'some_privilege')
  end

  # Ensures that ACL-wide rules apply to privileges for a particular Role
  def test_role_default_rule_set_privilege
    role_guest = Rend::Acl::Role.new('guest')
    @acl.add_role!(role_guest)
    @acl.allow!(role_guest)
    assert_equal true, @acl.allowed?(role_guest, nil, 'some_privilege')
    @acl.deny!(role_guest)
    assert_equal false, @acl.allowed?(role_guest, nil, 'some_privilege')
  end

  # Ensures that a privilege allowed for a particular Role upon all Resources works properly
  def test_role_privilege_allow
    role_guest = Rend::Acl::Role.new('guest')
    @acl.add_role!(role_guest)
    @acl.allow!(role_guest, nil, 'some_privilege')
    assert_equal true, @acl.allowed?(role_guest, nil, 'some_privilege')
  end

  # Ensures that a privilege denied for a particular Role upon all Resources works properly
  def test_role_privilege_deny
    role_guest = Rend::Acl::Role.new('guest')
    @acl.add_role!(role_guest)
    @acl.allow!(role_guest)
    @acl.deny!(role_guest, nil, 'some_privilege')
    assert_equal false, @acl.allowed?(role_guest, nil, 'some_privilege')
  end

  # Ensures that multiple privileges work properly for a particular Role
  def test_role_privileges
    role_guest = Rend::Acl::Role.new('guest')
    @acl.add_role!(role_guest)
    @acl.allow!(role_guest, nil, ['p1', 'p2', 'p3'])
    assert_equal true, @acl.allowed?(role_guest, nil, 'p1')
    assert_equal true, @acl.allowed?(role_guest, nil, 'p2')
    assert_equal true, @acl.allowed?(role_guest, nil, 'p3')
    assert_equal false, @acl.allowed?(role_guest, nil, 'p4')
    @acl.deny!(role_guest, nil, 'p1')
    assert_equal false, @acl.allowed?(role_guest, nil, 'p1')
    @acl.deny!(role_guest, nil, ['p2', 'p3'])
    assert_equal false, @acl.allowed?(role_guest, nil, 'p2')
    assert_equal false, @acl.allowed?(role_guest, nil, 'p3')
  end

  # Ensures that removing the default deny rule results in default deny rule
  def test_remove_default_deny
    assert_equal false, @acl.allowed?
    @acl.remove_deny!
    assert_equal false, @acl.allowed?
  end


  # Ensures that removing the default allow rule results in default deny rule being assigned
  def test_remove_default_allow
    @acl.allow!
    assert_equal true, @acl.allowed?
    @acl.remove_allow!
    assert_equal false, @acl.allowed?
  end

  # Ensures that removing non-existent default allow rule does nothing
  def test_remove_default_allow_non_existent
    @acl.remove_allow!
    assert_equal false, @acl.allowed?
  end

  # Ensures that removing non-existent default deny rule does nothing
  def test_remove_default_deny_non_existent
    @acl.allow!
    @acl.remove_deny!
    assert_equal true, @acl.allowed?
  end

  # Ensure that basic rule removal works
  def test_rules_remove
    @acl.allow!(nil, nil, ['privilege1', 'privilege2'])
    assert_equal false, @acl.allowed?
    assert_equal true,  @acl.allowed?(nil, nil, 'privilege1')
    assert_equal true,  @acl.allowed?(nil, nil, 'privilege2')

    @acl.remove_allow!(nil, nil, 'privilege1')
    assert_equal false, @acl.allowed?(nil, nil, 'privilege1')
    assert_equal true,  @acl.allowed?(nil, nil, 'privilege2')
  end

  # # Ensures that removal of a Role results in its rules being removed
  def test_rule_role_remove
    @acl.add_role!(Rend::Acl::Role.new('guest'))
    @acl.allow!('guest')
    assert_equal true, @acl.allowed?('guest')

    @acl.remove_role!('guest')
    assert_raises Rend::Acl::Role::Registry::Exception do
      @acl.allowed?('guest')
      flunk('Expected Rend::Acl::Role::Registry::Exception not thrown upon is_allowed on non-existent Role')
    end
    @acl.add_role!(Rend::Acl::Role.new('guest'))
    assert_equal false, @acl.allowed?('guest')
  end

  # Ensures that removal of all Roles results in Role-specific rules being removed
  def test_rule_role_remove_all
    @acl.add_role!(Rend::Acl::Role.new('guest'))
    @acl.allow!('guest')
    assert_equal true, @acl.allowed?('guest')
    @acl.remove_role_all!
    assert_raises Rend::Acl::Role::Registry::Exception do
      @acl.allowed?('guest')
      flunk('Expected Rend::Acl::Role::Registry::Exception not thrown upon is_allowed on non-existent Role')
    end
    @acl.add_role!(Rend::Acl::Role.new('guest'))
    assert_equal false, @acl.allowed?('guest')
  end

  # Ensures that removal of a Resource results in its rules being removed
  def test_rules_resource_remove
    @acl.add_resource!(Rend::Acl::Resource.new('area'))
    @acl.allow!(nil, 'area')
    assert_equal true, @acl.allowed?(nil, 'area')
    @acl.remove_resource!('area')
    assert_raises Rend::Acl::Exception do
        @acl.allowed?(nil, 'area')
        flunk('Expected Rend::Acl::Exception not thrown upon is_allowed on non-existent Resource')
    end
    @acl.add_resource!(Rend::Acl::Resource.new('area'))
    assert_equal false, @acl.allowed?(nil, 'area')
  end

  # Ensures that removal of all Resources results in Resource-specific rules being removed
  def test_rules_resource_remove_all
    @acl.add_resource!(Rend::Acl::Resource.new('area'))
    @acl.allow!(nil, 'area')
    assert_equal true, @acl.allowed?(nil, 'area')
    @acl.remove_resource_all!
    assert_raises Rend::Acl::Exception do
        @acl.allowed?(nil, 'area')
        flunk('Expected Rend::Acl::Exception not thrown upon is_allowed on non-existent Resource')
    end
    @acl.add_resource!(Rend::Acl::Resource.new('area'))
    assert_equal false, @acl.allowed?(nil, 'area')
  end

  # Ensures that an example for a content management system is operable
  def test_cms_example
    # Add some roles to the Role registry
    @acl.add_role!(Rend::Acl::Role.new('guest'))
    @acl.add_role!(Rend::Acl::Role.new('staff'), 'guest')  # staff inherits permissions from guest
    @acl.add_role!(Rend::Acl::Role.new('editor'), 'staff') # editor inherits permissions from staff
    @acl.add_role!(Rend::Acl::Role.new('administrator'))

    # Guest may only view content
    @acl.allow!('guest', nil, 'view')

    # Staff inherits view privilege from guest, but also needs additional privileges
    @acl.allow!('staff', nil, ['edit', 'submit', 'revise'])

    # Editor inherits view, edit, submit, and revise privileges, but also needs additional privileges
    @acl.allow!('editor', nil, ['publish', 'archive', 'delete'])

    # Administrator inherits nothing but is allowed all privileges
    @acl.allow!('administrator')

    # Access control checks based on above permission sets
    assert_equal true,  @acl.allowed?('guest', nil, 'view')
    assert_equal false, @acl.allowed?('guest', nil, 'edit')
    assert_equal false, @acl.allowed?('guest', nil, 'submit')
    assert_equal false, @acl.allowed?('guest', nil, 'revise')
    assert_equal false, @acl.allowed?('guest', nil, 'publish')
    assert_equal false, @acl.allowed?('guest', nil, 'archive')
    assert_equal false, @acl.allowed?('guest', nil, 'delete')
    assert_equal false, @acl.allowed?('guest', nil, 'unknown')
    assert_equal false, @acl.allowed?('guest')

    assert_equal true,  @acl.allowed?('staff', nil, 'view')
    assert_equal true,  @acl.allowed?('staff', nil, 'edit')
    assert_equal true,  @acl.allowed?('staff', nil, 'submit')
    assert_equal true,  @acl.allowed?('staff', nil, 'revise')
    assert_equal false, @acl.allowed?('staff', nil, 'publish')
    assert_equal false, @acl.allowed?('staff', nil, 'archive')
    assert_equal false, @acl.allowed?('staff', nil, 'delete')
    assert_equal false, @acl.allowed?('staff', nil, 'unknown')
    assert_equal false, @acl.allowed?('staff')

    assert_equal true,  @acl.allowed?('editor', nil, 'view')
    assert_equal true,  @acl.allowed?('editor', nil, 'edit')
    assert_equal true,  @acl.allowed?('editor', nil, 'submit')
    assert_equal true,  @acl.allowed?('editor', nil, 'revise')
    assert_equal true,  @acl.allowed?('editor', nil, 'publish')
    assert_equal true,  @acl.allowed?('editor', nil, 'archive')
    assert_equal true,  @acl.allowed?('editor', nil, 'delete')
    assert_equal false, @acl.allowed?('editor', nil, 'unknown')
    assert_equal false, @acl.allowed?('editor')

    assert_equal true,  @acl.allowed?('administrator', nil, 'view')
    assert_equal true,  @acl.allowed?('administrator', nil, 'edit')
    assert_equal true,  @acl.allowed?('administrator', nil, 'submit')
    assert_equal true,  @acl.allowed?('administrator', nil, 'revise')
    assert_equal true,  @acl.allowed?('administrator', nil, 'publish')
    assert_equal true,  @acl.allowed?('administrator', nil, 'archive')
    assert_equal true,  @acl.allowed?('administrator', nil, 'delete')
    assert_equal true,  @acl.allowed?('administrator', nil, 'unknown')
    assert_equal true,  @acl.allowed?('administrator')

    # Some checks on specific areas, which inherit access controls from the root ACL node
    @acl.add_resource!(Rend::Acl::Resource.new('newsletter'))
    @acl.add_resource!(Rend::Acl::Resource.new('pending'), 'newsletter')
    @acl.add_resource!(Rend::Acl::Resource.new('gallery'))
    @acl.add_resource!(Rend::Acl::Resource.new('profiles'), 'gallery')
    @acl.add_resource!(Rend::Acl::Resource.new('config'))
    @acl.add_resource!(Rend::Acl::Resource.new('hosts'), 'config')

    assert_equal true,  @acl.allowed?('guest', 'pending', 'view')
    assert_equal true,  @acl.allowed?('staff', 'profiles', 'revise')
    assert_equal true,  @acl.allowed?('staff', 'pending', 'view')
    assert_equal true,  @acl.allowed?('staff', 'pending', 'edit')
    assert_equal false, @acl.allowed?('staff', 'pending', 'publish')
    assert_equal false, @acl.allowed?('staff', 'pending')
    assert_equal false, @acl.allowed?('editor', 'hosts', 'unknown')
    assert_equal true,  @acl.allowed?('administrator', 'pending')

    # Add a new group, marketing, which bases its permissions on staff
    @acl.add_role!(Rend::Acl::Role.new('marketing'), 'staff')

    # Refine the privilege sets for more specific needs

    # Allow marketing to publish and archive newsletters
    @acl.allow!('marketing', 'newsletter', ['publish', 'archive'])

    # Allow marketing to publish and archive latest news
    @acl.add_resource!(Rend::Acl::Resource.new('news'))
    @acl.add_resource!(Rend::Acl::Resource.new('latest'), 'news')
    @acl.allow!('marketing', 'latest', ['publish', 'archive'])

    # Deny staff (and marketing, by inheritance) rights to revise latest news
    @acl.deny!('staff', 'latest', 'revise')

    # Deny everyone access to archive news announcements
    @acl.add_resource!(Rend::Acl::Resource.new('announcement'), 'news')
    @acl.deny!(nil, 'announcement', 'archive')

    # Access control checks for the above refined permission sets
    assert_equal true,  @acl.allowed?('marketing', nil, 'view')
    assert_equal true,  @acl.allowed?('marketing', nil, 'edit')
    assert_equal true,  @acl.allowed?('marketing', nil, 'submit')
    assert_equal true,  @acl.allowed?('marketing', nil, 'revise')
    assert_equal false, @acl.allowed?('marketing', nil, 'publish')
    assert_equal false, @acl.allowed?('marketing', nil, 'archive')
    assert_equal false, @acl.allowed?('marketing', nil, 'delete')
    assert_equal false, @acl.allowed?('marketing', nil, 'unknown')
    assert_equal false, @acl.allowed?('marketing')

    assert_equal true,  @acl.allowed?('marketing', 'newsletter', 'publish')
    assert_equal false, @acl.allowed?('staff', 'pending', 'publish')
    assert_equal true,  @acl.allowed?('marketing', 'pending', 'publish')
    assert_equal true,  @acl.allowed?('marketing', 'newsletter', 'archive')
    assert_equal false, @acl.allowed?('marketing', 'newsletter', 'delete')
    assert_equal false, @acl.allowed?('marketing', 'newsletter')

    assert_equal true,  @acl.allowed?('marketing', 'latest', 'publish')
    assert_equal true,  @acl.allowed?('marketing', 'latest', 'archive')
    assert_equal false, @acl.allowed?('marketing', 'latest', 'delete')
    assert_equal false, @acl.allowed?('marketing', 'latest', 'revise')
    assert_equal false, @acl.allowed?('marketing', 'latest')

    assert_equal false, @acl.allowed?('marketing', 'announcement', 'archive')
    assert_equal false, @acl.allowed?('staff', 'announcement', 'archive')
    assert_equal false, @acl.allowed?('administrator', 'announcement', 'archive')

    assert_equal false, @acl.allowed?('staff', 'latest', 'publish')
    assert_equal false, @acl.allowed?('editor', 'announcement', 'archive')

    # Remove some previous permission specifications

    # Marketing can no longer publish and archive newsletters
    @acl.remove_allow!('marketing', 'newsletter', ['publish', 'archive'])

    # Marketing can no longer archive the latest news
    @acl.remove_allow!('marketing', 'latest', 'archive')

    # Now staff (and marketing, by inheritance) may revise latest news
    @acl.remove_deny!('staff', 'latest', 'revise')

    # Access control checks for the above refinements

    assert_equal false, @acl.allowed?('marketing', 'newsletter', 'publish')
    assert_equal false, @acl.allowed?('marketing', 'newsletter', 'archive')
    assert_equal false, @acl.allowed?('marketing', 'latest', 'archive')
    assert_equal true,  @acl.allowed?('staff', 'latest', 'revise')
    assert_equal true,  @acl.allowed?('marketing', 'latest', 'revise')

    # Grant marketing all permissions on the latest news
    @acl.allow!('marketing', 'latest')

    # Access control checks for the above refinement
    assert_equal true, @acl.allowed?('marketing', 'latest', 'archive')
    assert_equal true, @acl.allowed?('marketing', 'latest', 'publish')
    assert_equal true, @acl.allowed?('marketing', 'latest', 'edit')
    assert_equal true, @acl.allowed?('marketing', 'latest')

  end

  # [NOT IMPLEMENTED YET] Ensures that the default rule obeys its assertion
  # def test_default_assert
  #   @acl.deny!(nil, nil, nil, Rend::Acl::Mock_assertion.new(false))
  #   assert_equal true, @acl.allowed?
  #   assert_equal true, @acl.allowed?(nil, nil, 'some_privilege')
  # end

  # Ensures that the only_parents argument to inherits_role? works
  # @group ZF-2502
  def test_role_inheritance_supports_checking_only_parents
    @acl.add_role!(Rend::Acl::Role.new('grandparent'))
    @acl.add_role!(Rend::Acl::Role.new('parent'), 'grandparent')
    @acl.add_role!(Rend::Acl::Role.new('child'), 'parent')
    assert_equal false, @acl.inherits_role?('child', 'grandparent', true)
  end

  # Returns an array of registered roles
  # @expected_exception PHPUnit_Framework_Error
  # @group ZF-5638
  # Porter Note: Seems like an odd test... investigate more
  def test_get_registered_roles
    @acl.add_role!('developer')

    roles = @acl.roles
    assert_kind_of Array, roles
    assert_equal false, roles.empty?
  end

  # Confirm that deleting a role after allowing access to all roles
  # raise undefined index error
  # @group ZF-5700
  # Porter Note: Seems like an odd test... investigate more
  def test_removing_role_after_it_was_allowed_access_to_all_resources_gives_error
    @acl.add_role!(Rend::Acl::Role.new('test0'))
    @acl.add_role!(Rend::Acl::Role.new('test1'))
    @acl.add_role!(Rend::Acl::Role.new('test2'))
    @acl.add_resource!(Rend::Acl::Resource.new('Test'))

    @acl.allow!(nil,'Test','xxx')

    # error test
    @acl.remove_role!('test0')

    # Check after fix
    assert_equal false, @acl.role?('test0')
  end

  # @group ZF-8039
  # Meant to test for the (in)existance of this notice:
  #   "Notice: Undefined index: all_privileges in lib/Zend/Acl.php on line 682"
  # Porter Note: Seems like an odd test... investigate more
  def test_method_remove_allow_does_not_throw_notice
    acl = Rend::Acl.new
    acl.add_role!('admin')
    acl.add_resource!('blog')
    acl.allow!('admin', 'blog', 'read')
    acl.remove_allow!(['admin'], ['blog'], nil)
  end

  def test_role_object_implements_to_string
    role = Rend::Acl::Role.new('_foo_bar_')
    assert_equal '_foo_bar_', role.to_s
  end

  def test_resource_object_implements_to_string
    resource = Rend::Acl::Resource.new('_foo_bar_')
    assert_equal '_foo_bar_', resource.to_s
  end


  # @group ZF-8468
  def test_roles
    assert_equal [], @acl.roles

    role_guest = Rend::Acl::Role.new('guest')
    @acl.add_role!(role_guest)
    @acl.add_role!(Rend::Acl::Role.new('staff'), role_guest)
    @acl.add_role!(Rend::Acl::Role.new('editor'), 'staff')
    @acl.add_role!(Rend::Acl::Role.new('administrator'))

    expected = %w[guest staff editor administrator]
    assert_equal expected, @acl.roles
  end

  # @group ZF-8468
  def test_resources
    assert_equal [], @acl.resources

    @acl.add_resource!(Rend::Acl::Resource.new('some_resource'))
    @acl.add_resource!(Rend::Acl::Resource.new('some_other_resource'))

    expected = ['some_resource', 'some_other_resource']
    assert_equal expected, @acl.resources
  end

  # @group ZF-9643
  def test_remove_allow_with_nil_resource_after_resource_specific_rules_applies_to_all_resources
    @acl.add_role!('guest')
    @acl.add_resource!('blogpost')
    @acl.add_resource!('newsletter')
    @acl.allow!('guest', 'blogpost', 'read')
    @acl.allow!('guest', 'newsletter', 'read')
    assert_equal true,  @acl.allowed?('guest', 'blogpost', 'read')
    assert_equal true,  @acl.allowed?('guest', 'newsletter', 'read')

    @acl.remove_allow!('guest', 'newsletter', 'read')
    assert_equal true,  @acl.allowed?('guest', 'blogpost', 'read')
    assert_equal false, @acl.allowed?('guest', 'newsletter', 'read')

    @acl.remove_allow!('guest', nil, 'read')
    assert_equal false, @acl.allowed?('guest', 'blogpost', 'read')
    assert_equal false, @acl.allowed?('guest', 'newsletter', 'read')

    # ensure allow nil/all resoures works
    @acl.allow!('guest', nil, 'read')
    assert_equal true,  @acl.allowed?('guest', 'blogpost', 'read')
    assert_equal true,  @acl.allowed?('guest', 'newsletter', 'read')
  end

  # @group ZF-9643
  def test_remove_deny_with_nil_resource_after_resource_specific_rules_applies_to_all_resources
    @acl.add_role!('guest')
    @acl.add_resource!('blogpost')
    @acl.add_resource!('newsletter')

    @acl.allow!
    @acl.deny!('guest', 'blogpost', 'read')
    @acl.deny!('guest', 'newsletter', 'read')
    assert_equal false, @acl.allowed?('guest', 'blogpost', 'read')
    assert_equal false, @acl.allowed?('guest', 'newsletter', 'read')

    @acl.remove_deny!('guest', 'newsletter', 'read')
    assert_equal false, @acl.allowed?('guest', 'blogpost', 'read')
    assert_equal true,  @acl.allowed?('guest', 'newsletter', 'read')

    @acl.remove_deny!('guest', nil, 'read')
    assert_equal true,  @acl.allowed?('guest', 'blogpost', 'read')
    assert_equal true,  @acl.allowed?('guest', 'newsletter', 'read')

    # ensure deny nil/all resources works
    @acl.deny!('guest', nil, 'read')
    assert_equal false, @acl.allowed?('guest', 'blogpost', 'read')
    assert_equal false, @acl.allowed?('guest', 'newsletter', 'read')
  end

  # Ensures that for a particular Role, a deny rule on a specific Resource is honored before an allow rule on the entire ACL
  def test_role_default_allow_rule_with_resource_deny_rule
    @acl.add_role!(Rend::Acl::Role.new('guest'))
    @acl.add_role!(Rend::Acl::Role.new('staff'), 'guest')
    @acl.add_resource!(Rend::Acl::Resource.new('area1'))
    @acl.add_resource!(Rend::Acl::Resource.new('area2'))
    @acl.deny!
    @acl.allow!('staff')
    @acl.deny!('staff', ['area1', 'area2'])
    assert_equal false, @acl.allowed?('staff', 'area1')
  end

  # Ensures that for a particular Role, a deny rule on a specific privilege is honored before an allow rule on the entire ACL
  def test_role_default_allow_rule_with_privilege_deny_rule
    @acl.add_role!(Rend::Acl::Role.new('guest'))
    @acl.add_role!(Rend::Acl::Role.new('staff'), 'guest')
    @acl.deny!
    @acl.allow!('staff')
    @acl.deny!('staff', nil, ['privilege1', 'privilege2'])
    assert_equal false, @acl.allowed?('staff', nil, 'privilege1')
  end

  # @group ZF-10649
  def test_allow_and_deny_with_nil_for_resources_will_apply_to_all_resources
    @acl.add_role!('guest')
    @acl.add_resource!('blogpost')

    @acl.allow!('guest')
    assert_equal true, @acl.allowed?('guest')
    assert_equal true, @acl.allowed?('guest', 'blogpost')
    assert_equal true, @acl.allowed?('guest', 'blogpost', 'read')

    @acl.deny!('guest')
    assert_equal false, @acl.allowed?('guest')
    assert_equal false, @acl.allowed?('guest', 'blogpost')
    assert_equal false, @acl.allowed?('guest', 'blogpost', 'read')
  end

  #### [TESTS TO BE IMPLEMENTED LATER] ####

  # # Ensures that assertions on privileges work properly for a particular Role
  # def test_role_privilege_assert
  #   role_guest = Rend::Acl::Role.new('guest')
  #   @acl.add_role!(role_guest)
  #              .allow!(role_guest, nil, 'some_privilege', Rend::Acl::Mock_assertion.new(true))
  #   assert_equal true, @acl.allowed?(role_guest, nil, 'some_privilege')
  #   @acl.allow!(role_guest, nil, 'some_privilege', Rend::Acl::Mock_assertion.new(false))
  #   assert_equal false, @acl.allowed?(role_guest, nil, 'some_privilege')
  # end

  # # Ensures that removing the default deny rule results in assertion method being removed
  # def test_remove_default_deny_assert
  #   @acl.deny!(nil, nil, nil, Rend::Acl::Mock_assertion.new(false))
  #   assert_equal true, @acl.allowed?
  #   @acl.remove_deny
  #   assert_equal false, @acl.allowed?
  # end


  # # @group ZF-1721
  # def test_acl_assertions_get_proper_role_when_inheritence_is_used
  #   acl = this._load_use_case1

  #   user = Rend::Acl::Role.new('publisher')
  #   blog_post = Rend::Acl::Resource.new('blog_post')

  #   # @var Zend_Acl_Use_case1_User_is_blog_post_owner_assertion
  #   assertion = acl.custom_assertion

  #   assert_equal true, acl.is_allowed(user, blog_post, 'modify')

  #   assert_equal 'publisher', assertion.last_assert_role.id

  # end

  # # @group ZF-1722
  # def test_acl_assertions_get_original_is_allowed_objects
  #   acl = this._load_use_case1

  #   user = Rend::Acl_Use_case1::User.new
  #   blog_post = Rend::Acl_Use_case1::Blog_post.new

  #   assert_equal true, acl.is_allowed(user, blog_post, 'view')

  #   /**
  #    * @var Zend_Acl_Use_case1_User_is_blog_post_owner_assertion
  #    */
  #   assertion = acl.custom_assertion

  #   assertion.assert_return_value = true
  #   user.role = 'contributor'
  #   assert_equal true, acl.is_allowed(user, blog_post, 'modify'), 'Assertion should return true'
  #   assertion.assert_return_value = false
  #   assert_equal false, acl.is_allowed(user, blog_post, 'modify'), 'Assertion should return false'

  #   # check to see if the last assertion has the proper objets
  #   assert_kind_of Zend_Acl_Use_case1_User, assertion.last_assert_role, 'Assertion did not recieve proper role object'
  #   assert_kind_of Zend_Acl_Use_case1_Blog_post, assertion.last_assert_resource, 'Assertion did not recieve proper resource object'

  # end

  # # @group ZF-7973
  # def test_acl_passes_privilege_to_assert_class {
  #   require_once dirname(__FILE__) . '/_files/Assertion_z_f7973.php'
  #   assertion = Rend::Acl_Acl_test::Assertion_z_f7973.new

  #   acl = Rend::Acl.new
  #   acl.add_role!('role')
  #   acl.add_resource!('resource')
  #   acl.allow!('role',nil,nil,assertion)
  #   allowed = acl.is_allowed('role','resource','privilege',assertion)

  #   assert_equal true, allowed
  # end


  protected

  # def use_case_2
  #   @acl.add_role!('guest')
  #   @acl.add_role!('contributor', 'guest')
  #   @acl.add_role!('publisher', 'contributor')
  #   @acl.add_role!('admin')
  #   @acl.add_resource!('blogPost')
  #   @acl.allow!('guest', 'blogPost', 'view')
  #   @acl.allow!('contributor', 'blogPost', 'contribute')
  #   @acl.allow!('contributor', 'blogPost', 'modify', @acl.customAssertion)
  #   @acl.allow!('publisher', 'blogPost', 'publish')
  # end

  # http:#framework.zend.com/manual/1.12/en/zend.acl.introduction.html#zend.acl.introduction.role_registry
  def use_case_1
    acl = Rend::Acl.new

    guest_role = Rend::Acl::Role.new('guest')

    acl.add_role! guest_role
    acl.add_role! Rend::Acl::Role.new('staff'), guest_role
    acl.add_role! Rend::Acl::Role.new('editor'), 'staff'
    acl.add_role! Rend::Acl::Role.new('administrator')

    # Guest may only view content
    acl.allow! guest_role, nil, 'view'

    # Staff inherits view privilege from guest, but also needs additional privileges
    acl.allow! 'staff', nil, %w[edit submit revise]

    # Editor inherits view, edit, submit, and revise privileges from staff, but also needs additional privileges
    acl.allow! 'editor', nil, %w[publish archive delete]

    # Administrator inherits nothing, but is allowed all privileges
    acl.allow! 'administrator'

    # Add new marketing group that inherits permissions from staff
    acl.add_role!(Rend::Acl::Role.new('marketing'), 'staff')

    # == Create Resources for the rules ===

    acl.add_resource!(Rend::Acl::Resource.new('newsletter'))
    acl.add_resource!(Rend::Acl::Resource.new('news'))
    acl.add_resource!(Rend::Acl::Resource.new('latest'), 'news')
    acl.add_resource!(Rend::Acl::Resource.new('announcement'), 'news')

    # === Setting up access ====

    # Marketing must be able to publish and archive newsletters and the latest news
    acl.allow!('marketing', ['newsletter', 'latest'], ['publish', 'archive'])

    # Staff (and marketing, by inheritance), are denied permission to revise the latest news
    acl.deny!('staff', 'latest', 'revise')

    # Everyone (including administrators) are denied permission to archive news announcements
    acl.deny!(nil, 'announcement', 'archive')

    acl
  end

  def assert_use_case_1(acl)
    assert_equal false, acl.allowed?('staff'         , 'newsletter'   , 'publish') # denied
    assert_equal true,  acl.allowed?('marketing'     , 'newsletter'   , 'publish') # allowed
    assert_equal false, acl.allowed?('staff'         , 'latest'       , 'publish') # denied
    assert_equal true,  acl.allowed?('marketing'     , 'latest'       , 'publish') # allowed
    assert_equal true,  acl.allowed?('marketing'     , 'latest'       , 'archive') # allowed
    assert_equal false, acl.allowed?('marketing'     , 'latest'       , 'revise')  # denied
    assert_equal false, acl.allowed?('editor'        , 'announcement' , 'archive') # denied
    assert_equal false, acl.allowed?('administrator' , 'announcement' , 'archive') # denied
  end
end