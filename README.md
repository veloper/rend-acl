# Rend Acl

[![Build Status](https://travis-ci.org/veloper/rend-acl.png?branch=master)](https://travis-ci.org/veloper/rend-acl)
[![Coverage Status](https://coveralls.io/repos/veloper/rend-acl/badge.png)](https://coveralls.io/r/veloper/rend-acl)
[![Dependency Status](https://gemnasium.com/veloper/rend-acl.png)](https://gemnasium.com/veloper/rend-acl)

Rend-Acl is a port of [Zend_Acl](http://framework.zend.com/manual/1.12/en/zend.acl.html) with modifications made to bring the api more inline with Ruby conventions.

## Introduction
Rend-Acl provides a lightweight and flexible access control list (ACL) implementation for privileges management. In general, an application may utilize such ACL's to control access to certain protected objects by other requesting objects.

For the purposes of this documentation:

* A **Role** is an object that may request access to a Resource or Privilege.
    * _(e.g., "Passenger", "Driver", "Mechanic")_
* A **Resource** is an object to which access is controlled.
    * _(e.g., "Car", "Boat", "Train")_
* A **Privilege** is an _(optional)_ level of control which enables further refinement.
    * _(e.g., "Drive", "Sell", "Repair")_

Through use of an ACL an application may control how roles are granted access to resources and privilages.

### Still Lost?
These terms and concepts become easier to understand when translated into plain english...

```ruby
@acl.allow! :role => "Driver", :resource => "Car"
```
> __Translation:__ Allow a **Driver** full-access to the **Car**.

```ruby
@acl.allow! :role => "Driver", :resource => "Car", :privilege => "Sell"
```
> __Translation:__ Allow a **Driver** to **Sell** the **Car**.

```ruby
@acl.allow! :role => "Mechanic", :privilege => "Repair"
```
> __Translation:__ Allow a **Mechanic** to **Repair** anything.


## Basic Usage Example

```ruby
# ==> Initialize ACL Object
@acl = Rend::Acl.new

# ==> Add Roles & Resources to ACL
@acl.add! :role     => ["Passenger", "Driver", "Mechanic"],
          :resource => ["Car", "Boat", "Train"]

# ==> Declare Rules - Note: When conflicts occur the last rule always wins!

# Translation: Allow the "Driver" Role full-access to the "Car" Resource.
@acl.allow! :role => "Driver", :resource => "Car"

# Translation: Allow the "Mechanic" Role the privilege to "Repair" any Resouece.
@acl.allow! :role => "Mechanic", :privilege => "Repair"

# Translation: Allow all Roles the privilege to "Look" at any Resouece.
@acl.allow! :privilege => "Look"

# Translation: Deny all Roles any access to the "Train" Resource.
@acl.deny! :resource => "Train"

# ==> Querying
@acl.allowed?(:role => "Driver",    :resource => "Car")                           # TRUE
@acl.allowed?(:role => "Passenger", :resource => "Car")                           # FALSE
@acl.allowed?(:role => "Mechanic",  :resource => "Car")                           # FALSE
@acl.allowed?(:role => "Mechanic",  :privilege => "Repair")                       # TRUE
@acl.allowed?(:role => "Passenger", :privilege => "Look")                         # TRUE
@acl.allowed?(:role => "Passenger", :resource => "Train")                         # FALSE
@acl.allowed?(:role => "Mechanic",  :resource => "Train", :privilege => "Repair") # FALSE
```

## Installation

Install this gem directly using...

    gem install rend-acl

... or simply include it in your project's `Gemfile` ...

    gem 'rend-acl', '~> 0.0.4'


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes **(with passing tests please!)** (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
6. ???
7. Profit!

## Licensing

* All ported Ruby code and assoicated 'Rend' gems are under a simple [New-BSD License](http://dan.doezema.com/licenses/new-bsd).
* Original PHP code is licensed under [Zend's New-BSD License](http://framework.zend.com/license/).
    * This license can be found in `./ZEND_FRAMEWORK_LICENSE.txt`

## Acknowledgements

* This project is **NOT** associated with, or endorsed by, Zend Technologies USA, Inc., nor any of its contributors.
* Rend's modular design was heavily influced by [RSpec](https://github.com/rspec/rspec)'s approach.