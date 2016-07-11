begin
  require 'vagrant'
rescue LoadError
  raise 'The Vagrant landrush plugin must be run within Vagrant.'
end

# Only load the gem on Windows since it replaces some methods in Ruby's Process class
# Also load before Process.uid is called the first time by Vagrant
require 'win32/process' if Vagrant::Util::Platform.windows?

require 'rubydns'

require 'landrush/dependent_vms'
require 'landrush/plugin'
require 'landrush/server'
require 'landrush/store'
require 'landrush/version'
require 'landrush-ip'
