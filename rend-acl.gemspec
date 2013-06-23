# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rend/acl/version'

Gem::Specification.new do |spec|
  spec.name          = "rend-acl"
  spec.version       = Rend::Acl::Version::STRING
  spec.authors       = ["Daniel Doezema"]
  spec.email         = ["daniel.doezema@gmail.com"]
  spec.description   = "A port of Zend_Acl with modifications made to bring the API more inline with Ruby conventions."
  spec.summary       = "rend-acl-#{Rend::Acl::Version::STRING}"
  spec.homepage      = "https://github.com/veloper/rend-acl"
  spec.license       = "New-BSD"

  spec.files         = `git ls-files`.split($/)
  spec.files        += ["LICENSE.txt", "ZEND_FRAMEWORK_LICENSE.txt"]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features|)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "turn"


  dependency_gems = ['rend-core']
  dependency_gems.each do |gem_name|
    if Rend::Acl::Version::STRING =~ /[a-zA-Z]+/
      spec.add_runtime_dependency "#{gem_name}", "= #{Rend::Acl::Version::STRING}"
    else
      spec.add_runtime_dependency "#{gem_name}", "~> #{Rend::Acl::Version::STRING.split('.')[0..1].concat(['0']).join('.')}"
    end
  end
end
