Feature: landrush-ip
  Landrush should pick the desired IP, given multiple network interfaces.

  Scenario Outline: booting a box and picking a specific interface
    Given a file named "Vagrantfile" with:
    """
    Vagrant.configure('2') do |config|
      config.vm.box = '<box>'
      config.vm.hostname = 'my-host.landrush-acceptance-test'

      config.vm.network :private_network, type: 'dhcp'
      config.vm.network :private_network, type: 'dhcp'
      config.vm.network :private_network, type: 'dhcp'
      config.vm.network :private_network, type: 'dhcp'
      config.vm.network :private_network, type: 'dhcp'

      config.vm.synced_folder '.', '/vagrant', disabled: true

      config.landrush.enabled = true
      config.landrush.tld = 'landrush-acceptance-test'
      config.landrush.host_interface = 'eth3'
      config.landrush.host_interface_excludes = [/eth[0-9]+/]
    end
    """
    When I successfully run `bundle exec vagrant up --provider <provider>`
    Then the host visible IP address of the guest is the IP of interface "eth3"

    Examples:
      | box             | provider   |
      | debian/jessie64 | virtualbox |

  Scenario Outline: booting a box and excluding interfaces it should pick the last interface
    Given a file named "Vagrantfile" with:
    """
    Vagrant.configure('2') do |config|
      config.vm.box = '<box>'
      config.vm.hostname = 'my-host.landrush-acceptance-test'

      config.vm.network :private_network, type: 'dhcp'
      config.vm.network :private_network, type: 'dhcp'
      config.vm.network :private_network, type: 'dhcp'
      config.vm.network :private_network, type: 'dhcp'
      config.vm.network :private_network, type: 'dhcp'

      config.vm.synced_folder '.', '/vagrant', disabled: true

      config.landrush.enabled = true
      config.landrush.tld = 'landrush-acceptance-test'
      config.landrush.host_interface_excludes = [/eth1/, /eth2/, /eth5/]
    end
    """
    When I successfully run `bundle exec vagrant up --provider <provider>`
    Then the host visible IP address of the guest is the IP of interface "eth4"

    Examples:
      | box             | provider   |
      | debian/jessie64 | virtualbox |
