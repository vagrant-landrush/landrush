begin
  require 'vagrant'
rescue LoadError
  raise 'The Vagrant RubyDNS plugin must be run within Vagrant.'
end

module VagrantRubydns
  def self.working_dir
    @working_dir ||= Pathname(File.expand_path('~/.vagrant_rubydns')).tap(&:mkpath)
  end

  def self.working_dir=(working_dir)
    @working_dir = Pathname(working_dir).tap(&:mkpath)
  end
end

require 'vagrant-rubydns/plugin'
require 'vagrant-rubydns/store'
require 'vagrant-rubydns/dependent_vms'
require 'vagrant-rubydns/server'
require 'vagrant-rubydns/util'
require 'vagrant-rubydns/version'
