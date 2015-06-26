# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'chef-backup/version'

Gem::Specification.new do |spec|
  spec.name          = "chef-backup"
  spec.version       = ChefBackup::VERSION
  spec.authors       = ["Angelo Olivera"]
  spec.email         = ["aolivera@mongodb.com"]
  spec.summary       = %q{Back up Chef objects to a Git repository.}
  spec.homepage      = ""
  spec.license       = "GPL"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_runtime_dependency "chef", "~> 12.0"
  spec.add_runtime_dependency "git", "~> 1.2"

end
