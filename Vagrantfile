# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure('2') do |config|
  config.vm.define 'landrush-test-debian' do |machine|
    machine.vm.box = 'debian/jessie64'

    # Add a DHCP network so we don't know its IP :P
    machine.vm.network 'private_network', type: 'dhcp'

    machine.vm.provider :virtualbox do |provider, _|
      provider.memory = 512
      provider.cpus = 2
    end

    machine.landrush_ip.override = true

    machine.vm.hostname = 'landrush-dev'
    machine.vm.network 'private_network', type: 'dhcp'

    # Landrush (DNS)
    machine.landrush.enabled = true
    machine.landrush.tld = 'landrush'
    machine.landrush.interface = 'eth1'
    machine.landrush.exclude = [/lo[0-9]*/, /docker[0-9]+/, /tun[0-9]+/]
  end
end
