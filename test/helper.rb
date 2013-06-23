# https://coveralls.io Integration
require 'coveralls'
Coveralls.wear_merged!

# Gem
require 'rend/acl'

# Testing Support
require 'support/mock_assertion'
require 'support/passing_assertion'
require 'support/failing_assertion'

# Autorun tests
require "minitest/autorun"

# Optionally try to use TURN gem if we're in a RUBY_VERSION >= 1.9.3 environment
if Gem::Version.new(RUBY_VERSION) > Gem::Version.new('1.9.2')
  begin; require 'turn/autorun'; rescue LoadError; end
end