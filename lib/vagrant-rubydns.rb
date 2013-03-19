begin
  require "vagrant"
rescue LoadError
  raise "The Vagrant RubyDNS plugin must be run within Vagrant."
end

require "vagrant-rubydns/version"
require "vagrant-rubydns/plugin"

module VagrantRubydns
end

