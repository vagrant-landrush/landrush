# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vagrant-rubydns/version'

Gem::Specification.new do |spec|
  spec.name          = "vagrant-rubydns"
  spec.version       = Vagrant::Rubydns::VERSION
  spec.authors       = ["Paul Hinze"]
  spec.email         = ["paul.t.hinze@gmail.com"]
  spec.description   = %q{see https://github.com/phinze/vagrant-rubydns}
  spec.summary       = %q{a simple dns server for vagrant guests}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "rubydns"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
