module Exam

  class << self
    def require_all!
      return if @required
      Dir[File.dirname(__FILE__) + '/exam/**/*.rb'].each {|x| require x}
      @required = true
    end
  end

end