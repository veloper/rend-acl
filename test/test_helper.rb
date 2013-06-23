# Gem
require 'rend/acl'

# Testing Support
require 'support/mock_assertion'
require 'support/passing_assertion'
require 'support/failing_assertion'

# Auto run tests=
require "minitest/autorun"

# Optionally try to use TURN gem
begin; require 'turn/autorun'; rescue LoadError; end

# https://coveralls.io Integration
require 'coveralls'
Coveralls.wear!
