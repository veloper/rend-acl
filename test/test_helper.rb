# Gem
require 'rend/acl'

# Testing Support
require 'support/mock_assertion'
require 'support/passing_assertion'
require 'support/failing_assertion'

# Auto run tests with Turn gem.
require "minitest/autorun"
require "turn/autorun"

# https://coveralls.io Integration
require 'coveralls'
Coveralls.wear!
