require 'test/unit'
require 'rend/acl'

class AclTest < Test::Unit::TestCase

  # See: http://framework.zend.com/manual/1.12/en/zend.acl.introduction.html#zend.acl.introduction.roles
  def test_multiple_inheritance_among_roles
    @acl = Rend::Acl.new
    @acl.add_role!('guest').add_role!('member').add_role!('admin')

    parents = %w[guest member admin]
    @acl.add_role! 'Daniel Doezema', parents

    @acl.add_resource!('gold')

    @acl.deny!('guest', 'gold')
    @acl.allow!('member', 'gold')

    assert_equal true, @acl.allowed?('Daniel Doezema', 'gold')
  end

  # http://framework.zend.com/manual/1.12/en/zend.acl.introduction.html#zend.acl.introduction.role_registry
  def test_registering_roles
    @acl = Rend::Acl.new
    guest_role = Rend::Acl::Role.new('guest')
    @acl.add_role! guest_role
    @acl.add_role! Rend::Acl::Role.new('staff'), guest_role
    @acl.add_role! Rend::Acl::Role.new('editor'), 'staff'
    @acl.add_role! Rend::Acl::Role.new('administrator')

    # Guest may only view content
    @acl.allow! guest_role, nil, 'view'

    # Staff inherits view privilege from guest, but also needs additional
    # privileges
    @acl.allow! 'staff', nil, %w[edit submit revise]

    # Editor inherits view, edit, submit, and revise privileges from
    # staff, but also needs additional privileges
    @acl.allow! 'editor', nil, %w[publish archive delete]

    # Administrator inherits nothing, but is allowed all privileges
    @acl.allow! 'administrator'


    assert_equal true,  @acl.allowed?('guest', nil, 'view')
    assert_equal false, @acl.allowed?('staff', nil, 'publish')
    assert_equal true,  @acl.allowed?('staff', nil, 'revise')
    assert_equal true,  @acl.allowed?('editor', nil, 'view')          # allowed because of inheritance from guest
    assert_equal false, @acl.allowed?('editor', nil, 'update')        # denied because no allow rule for 'update'
    assert_equal true,  @acl.allowed?('administrator', nil, 'view')   # allowed because administrator is allowed all privileges
    assert_equal true,  @acl.allowed?('administrator')                # allowed because administrator is allowed all privileges
    assert_equal true,  @acl.allowed?('administrator', nil, 'update') # allowed because administrator is allowed all privileges
  end

  # http://framework.zend.com/manual/1.12/en/zend.acl.introduction.html#zend.acl.introduction.role_registry
  def test_precise_access_controls
    @acl = Rend::Acl.new
    guest_role = Rend::Acl::Role.new('guest')
    @acl.add_role! guest_role
    @acl.add_role! Rend::Acl::Role.new('staff'), guest_role
    @acl.add_role! Rend::Acl::Role.new('editor'), 'staff'
    @acl.add_role! Rend::Acl::Role.new('administrator')

    # Guest may only view content
    @acl.allow! guest_role, nil, 'view'

    # Staff inherits view privilege from guest, but also needs additional
    # privileges
    @acl.allow! 'staff', nil, %w[edit submit revise]

    # Editor inherits view, edit, submit, and revise privileges from
    # staff, but also needs additional privileges
    @acl.allow! 'editor', nil, %w[publish archive delete]

    # Administrator inherits nothing, but is allowed all privileges
    @acl.allow! 'administrator'

    # The new marketing group inherits permissions from staff
    @acl.add_role!(Rend::Acl::Role.new('marketing'), 'staff')

    # === Create Resources for the rules ===

    # newsletter
    @acl.add_resource!(Rend::Acl::Resource.new('newsletter'))

    # news
    @acl.add_resource!(Rend::Acl::Resource.new('news'))

    # latest news
    @acl.add_resource!(Rend::Acl::Resource.new('latest'), 'news')

    # announcement news
    @acl.add_resource!(Rend::Acl::Resource.new('announcement'), 'news')

    # === Setting up access ====

    # Marketing must be able to publish and archive newsletters and the latest news
    @acl.allow!('marketing', ['newsletter', 'latest'], ['publish', 'archive'])

    # Staff (and marketing, by inheritance), are denied permission to revise the latest news
    @acl.deny!('staff', 'latest', 'revise')

    # Everyone (including administrators) are denied permission to archive news announcements
    @acl.deny!(nil, 'announcement', 'archive')


    # === Testing ===

    assert_equal false, @acl.allowed?('staff'         , 'newsletter'   , 'publish') # denied
    assert_equal true,  @acl.allowed?('marketing'     , 'newsletter'   , 'publish') # allowed
    assert_equal false, @acl.allowed?('staff'         , 'latest'       , 'publish') # denied
    assert_equal true,  @acl.allowed?('marketing'     , 'latest'       , 'publish') # allowed
    assert_equal true,  @acl.allowed?('marketing'     , 'latest'       , 'archive') # allowed
    assert_equal false, @acl.allowed?('marketing'     , 'latest'       , 'revise')  # denied
    assert_equal false, @acl.allowed?('editor'        , 'announcement' , 'archive') # denied
    assert_equal false, @acl.allowed?('administrator' , 'announcement' , 'archive') # denied

    # === Removing Access Controls ===
    # To remove one or more access rules from the ACL, simply use the available removeAllow()
    # or removeDeny() methods. As with allow() and deny(), you may provide a NULL value to indicate
    # application to all roles, resources, and/or privileges:

    # Remove the denial of revising latest news to staff (and marketing, by inheritance)
    @acl.remove_deny!('staff', 'latest', 'revise')
    assert_equal true, @acl.allowed?('marketing', 'latest', 'revise')

    # Remove the allowance of publishing and archiving newsletters to marketing
    @acl.remove_allow!('marketing', 'newsletter', ['publish', 'archive'])
    assert_equal false, @acl.allowed?('marketing', 'newsletter', 'publish')
    assert_equal false, @acl.allowed?('marketing', 'newsletter', 'archive')

    # === Modifying Access Controls ===
    # Privileges may be modified incrementally as indicated above, but a NIL
    # value for the privileges overrides such incremental changes:

    # Allow marketing all permissions upon the latest news
    @acl.allow!('marketing', 'latest')
    assert_equal true, @acl.allowed?('marketing', 'latest', 'publish')  # allowed
    assert_equal true, @acl.allowed?('marketing', 'latest', 'archive')  # allowed
    assert_equal true, @acl.allowed?('marketing', 'latest', 'anything') # allowed
  end

  def test_storing_acl_data_for_persistence_with_marshal
    @acl = Rend::Acl.new
    guest_role = Rend::Acl::Role.new('guest')
    @acl.add_role! guest_role
    @acl.add_role! Rend::Acl::Role.new('staff'), guest_role
    @acl.add_role! Rend::Acl::Role.new('editor'), 'staff'
    @acl.add_role! Rend::Acl::Role.new('administrator')

    # Guest may only view content
    @acl.allow! guest_role, nil, 'view'

    # Staff inherits view privilege from guest, but also needs additional
    # privileges
    @acl.allow! 'staff', nil, %w[edit submit revise]

    # Editor inherits view, edit, submit, and revise privileges from
    # staff, but also needs additional privileges
    @acl.allow! 'editor', nil, %w[publish archive delete]

    # Administrator inherits nothing, but is allowed all privileges
    @acl.allow! 'administrator'

    # The new marketing group inherits permissions from staff
    @acl.add_role!(Rend::Acl::Role.new('marketing'), 'staff')

    # === Create Resources for the rules ===

    # newsletter
    @acl.add_resource!(Rend::Acl::Resource.new('newsletter'))

    # news
    @acl.add_resource!(Rend::Acl::Resource.new('news'))

    # latest news
    @acl.add_resource!(Rend::Acl::Resource.new('latest'), 'news')

    # announcement news
    @acl.add_resource!(Rend::Acl::Resource.new('announcement'), 'news')

    # === Setting up access ====

    # Marketing must be able to publish and archive newsletters and the latest news
    @acl.allow!('marketing', ['newsletter', 'latest'], ['publish', 'archive'])

    # Staff (and marketing, by inheritance), are denied permission to revise the latest news
    @acl.deny!('staff', 'latest', 'revise')

    # Everyone (including administrators) are denied permission to archive news announcements
    @acl.deny!(nil, 'announcement', 'archive')

    encoded_acl = Marshal.dump(@acl)
    decoded_acl = Marshal.load(encoded_acl)

    # === Testing ===

    assert_equal false, decoded_acl.allowed?('staff'         , 'newsletter'   , 'publish') # denied
    assert_equal true,  decoded_acl.allowed?('marketing'     , 'newsletter'   , 'publish') # allowed
    assert_equal false, decoded_acl.allowed?('staff'         , 'latest'       , 'publish') # denied
    assert_equal true,  decoded_acl.allowed?('marketing'     , 'latest'       , 'publish') # allowed
    assert_equal true,  decoded_acl.allowed?('marketing'     , 'latest'       , 'archive') # allowed
    assert_equal false, decoded_acl.allowed?('marketing'     , 'latest'       , 'revise')  # denied
    assert_equal false, decoded_acl.allowed?('editor'        , 'announcement' , 'archive') # denied
    assert_equal false, decoded_acl.allowed?('administrator' , 'announcement' , 'archive') # denied

  end
end