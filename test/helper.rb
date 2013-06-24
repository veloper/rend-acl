# https://coveralls.io Integration
require 'coveralls'
Coveralls.wear!

# Gem
require 'rend/acl'

# Testing Support
require 'support/mock_assertion'
require 'support/passing_assertion'
require 'support/failing_assertion'

# Autorun tests
require "minitest/autorun"
