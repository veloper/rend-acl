require 'test_helper'

class WikiPagesResourcesTest < MiniTest::Unit::TestCase

    def setup
      @acl = Rend::Acl.new
    end

    def test_resource_inheritance_example
      city_resource     = Rend::Acl::Resource.new("city")
      building_resource = Rend::Acl::Resource.new("building")

      @acl.add_resource!(city_resource)
      @acl.add_resource!(building_resource, city_resource)

      mayor_role = Rend::Acl::Role.new("mayor")
      @acl.add_role!(mayor_role)

      @acl.allow! :role => mayor_role, :resource => city_resource

      assert_equal true, @acl.allowed?(:role => mayor_role, :resource => city_resource)
      assert_equal true, @acl.allowed?(:role => mayor_role, :resource => building_resource)
    end

end