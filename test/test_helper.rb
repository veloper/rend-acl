# Gem
require 'rend/acl'

# Support
require 'support/mock_assertion'
require 'support/passing_assertion'
require 'support/failing_assertion'

# Purdy!
require "minitest/reporters"
MiniTest::Reporters.use!

# https://coveralls.io Integration
require 'coveralls'
Coveralls.wear!

# # Wiki Tests
# Dir[File.dirname(__FILE__) + 'test/wiki/**/*.rb'].select{|x|x.match(/\/test_.*?\.rb$/)}.each do |file|
#   require file
# end

# Testing
require "minitest/autorun"