begin
  require 'vagrant'
rescue LoadError
  raise 'The Vagrant landrush plugin must be run within Vagrant.'
end

require 'rubydns'
require 'ipaddr'

require 'landrush/dependent_vms'
require 'landrush/plugin'
require 'landrush/resolver_config'
require 'landrush/server'
require 'landrush/store'
require 'landrush/version'
