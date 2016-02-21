Feature: dns_resolution
  Landrush should make a virtual machine's IP address DNS-resolvable.

  Scenario Outline: booting a box
    Given a file named "Vagrantfile" with:
    """
    Vagrant.configure('2') do |config|
      config.vm.box = '<box>'
      config.vm.hostname = 'my-host.my-tld'
      config.vm.network :private_network, ip: '10.10.10.123'

      config.landrush.enabled = true
      config.landrush.tld = 'my-tld'
    end
    """
    When I successfully run `bundle exec vagrant up --provider <provider>`
    Then the hostname "my-host.my-tld" should resolve to "10.10.10.123" on the internal DNS server
    And the hostname "my-host.my-tld" should resolve to "10.10.10.123" on the host
    And the hostname "my-host.my-tld" should resolve to "10.10.10.123" on the guest

    Examples:
      | box             | provider   |
      | debian/jessie64 | virtualbox |
      | ubuntu/wily64   | virtualbox |
