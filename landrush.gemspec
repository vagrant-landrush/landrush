# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'landrush/version'

Gem::Specification.new do |spec|
  spec.name          = 'landrush'
  spec.version       = Landrush::VERSION
  spec.authors       = ['Paul Hinze']
  spec.email         = ['paul.t.hinze@gmail.com']
  spec.description   = <<-DESCRIP.gsub(/^    /, '')
    Forget about IPs in Vagrant - Automated DNS for your VMs

    This Vagrant plugin spins up a lightweight DNS server and makes it visible
    to your guests and your host, so that you can easily access all your
    machines without having to fiddle with IP addresses.

    DNS records are automatically added and removed as machines are brought up
    and down, and you can configure static entries to be returned from the
    server as well. See the README for more documentation.
  DESCRIP
  spec.summary       = 'a vagrant plugin providing consistent DNS visible on host and guests'
  spec.homepage      = 'https://github.com/vagrant-landrush/landrush'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'rubydns', '0.8.5'
  spec.add_dependency 'win32-process'
  spec.add_dependency 'landrush-ip', '~> 0.2.5'
end
