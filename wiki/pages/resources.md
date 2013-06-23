# Resources
A ***Resource*** is simply an object to which access is controlled.


## Resource Class
Rend-Acl provides the `Rend::Acl::Resource` class as a basic resource implementation for developers to use and/or extend as needed.


## Tree Structure
Rend-Acl provides a tree structure to which multiple resources can be added. Since resources are stored in such a tree structure, they can be organized from the general (toward the tree root) to the specific (toward the tree leaves). Queries on a specific resource will automatically search the resource's hierarchy for rules assigned to ancestor resources, allowing for simple inheritance of rules.


## Resource Inheritance
For example, if a default ***rule*** is to be applied to each ***building*** in a ***city***, one would simply assign the ***rule*** to the ***city***, instead of assigning the same ***rule*** to each ***building***. Some ***building***s may require exceptions to such a ***rule***, however, and this can be achieved in Rend-Acl by assigning such exception ***rule***s to each ***building*** that requires such an exception. A ***resource*** may inherit from only one parent ***resource***, though this parent ***resource*** can have its own parent ***resource***, etc.

### Example
```ruby
@acl = Rend::Acl.new

# Define Resources
city_resource     = Rend::Acl::Resource.new("city")
building_resource = Rend::Acl::Resource.new("building")

# Add Resources to ACL
@acl.add_resource!(city_resource)
@acl.add_resource!(building_resource, city_resource) # Inheritance from city_resource

# Define & Add Roles
mayor_role = Rend::Acl::Role.new("mayor")
@acl.add_role!(mayor_role)

# Define Rules
@acl.allow! :role => mayor_role, :resource => city_resource

# Querying
@acl.allowed? :role => mayor_role, :resource => city_resource     # => TRUE, via explicitly set rule.
@acl.allowed? :role => mayor_role, :resource => building_resource # => TRUE, via resource rule inheritance
```
> **Example Test:** `rend-acl/test/test_wiki_pages_resources.rb#test_resource_inheritance_example` ***PASSING***