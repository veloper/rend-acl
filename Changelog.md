# Change Log

### Version 0.0.4 - June 11th, 2013

* Assertions
    * Implemented ported test coverage for this feature.
    * Implemented "Assertion" feature that exists in the original Zend_Acl library.

* Added a generic `acl.add!()` method which enables many intuitive ways to add Roles and Resources to the ACL.
    * See [Documentation In Code](https://github.com/veloper/rend-acl/blob/master/lib/rend/acl.rb#L51-L76) for usage examples.

* Added ability to me a bit more explicit with the following methods...
    * `.allow!()`
    * `.remove_allow!()`
    * `.deny!()`
    * `.remove_deny!()`
    * `.allowed?()`

    ... using hash with the options of ...

    * `:role`
    * `:resource`
    * `:prilvilege`
    * `:assertion` -- _Not utilized in `.allowed?()` method._

### Version <= 0.0.3
* Initial Port