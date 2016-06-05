Feature: landrush-ip
  Landrush should pick the desired IP, given multiple network interfaces.

  Scenario Outline: booting a box and picking a specific interface
    Given a file named "Vagrantfile" with:
    """
    Vagrant.configure('2') do |config|
      config.vm.box = '<box>'
      config.vm.hostname = 'my-host.landrush-acceptance-test'

      config.vm.network :private_network, ip: '192.168.50.50'
      config.vm.network :private_network, ip: '192.168.50.51'
      config.vm.network :private_network, ip: '192.168.50.52'
      config.vm.network :private_network, ip: '192.168.50.53'
      config.vm.network :private_network, ip: '192.168.50.54'

      config.vm.synced_folder '.', '/vagrant', disabled: true

      config.landrush.enabled = true
      config.landrush.tld = 'landrush-acceptance-test'
      config.landrush.interface = 'eth3'
      config.landrush.exclude = [/eth[0-9]+/]
    end
    """
    When I successfully run `bundle exec vagrant up --provider <provider>`
    Then the hostname "my-host.landrush-acceptance-test" should resolve to "192.168.50.52" on the internal DNS server
    And the hostname "my-host.landrush-acceptance-test" should resolve to "192.168.50.52" on the host
    And the hostname "my-host.landrush-acceptance-test" should resolve to "192.168.50.52" on the guest

    Examples:
      | box             | provider   |
      | debian/jessie64 | virtualbox |
      #| ubuntu/wily64   | virtualbox |

  Scenario Outline: booting a box and excluding interfaces it should pick the last interface
    Given a file named "Vagrantfile" with:
    """
    Vagrant.configure('2') do |config|
      config.vm.box = '<box>'
      config.vm.hostname = 'my-host.landrush-acceptance-test'

      config.vm.network :private_network, ip: '192.168.50.50'
      config.vm.network :private_network, ip: '192.168.50.51'
      config.vm.network :private_network, ip: '192.168.50.52'
      config.vm.network :private_network, ip: '192.168.50.53'
      config.vm.network :private_network, ip: '192.168.50.54'

      config.vm.synced_folder '.', '/vagrant', disabled: true

      config.landrush.enabled = true
      config.landrush.tld = 'landrush-acceptance-test'
      config.landrush.exclude = [/eth1/, /eth2/, /eth5/]
    end
    """
    When I successfully run `bundle exec vagrant up --provider <provider>`
    Then the hostname "my-host.landrush-acceptance-test" should resolve to "192.168.50.53" on the internal DNS server
    And the hostname "my-host.landrush-acceptance-test" should resolve to "192.168.50.53" on the host
    And the hostname "my-host.landrush-acceptance-test" should resolve to "192.168.50.53" on the guest

    Examples:
      | box             | provider   |
      | debian/jessie64 | virtualbox |
      #| ubuntu/wily64   | virtualbox |
