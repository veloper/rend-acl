# https://coveralls.io Integration
require 'coveralls'
Coveralls.wear_merged!

# Gem
require 'rend/acl'

# Testing Support
require 'support/mock_assertion'
require 'support/passing_assertion'
require 'support/failing_assertion'

# Exam Mixins
require 'exam'
Exam.require_all!

# Autorun tests
require "minitest/autorun"



class Minitest::Test

  def self.include_exams!
    name = self.name.gsub("Test", "")
    tests = Exam.const_defined?(name) ? Exam.const_get(name) : false

    if tests.respond_to?(:constants)
      tests.constants.each do |x|
        puts "including #{tests.const_get(x)}"
        include tests.const_get(x)
      end
    end
  end

end