Feature: dns_resolution
  Landrush should make a virtual machine's IP address DNS-resolvable.

  Scenario Outline: booting a box
    Given a file named "Vagrantfile" with:
    """
    Vagrant.configure('2') do |config|
      config.vm.box = '<box>'
      config.vm.hostname = 'my-host.landrush-acceptance-test'
      config.vm.network :private_network, ip: '10.10.10.123'

      config.vm.synced_folder '.', '/vagrant', disabled: true

      config.landrush.enabled = true
      config.landrush.tld = 'landrush-acceptance-test'
    end
    """
    When I successfully run `bundle exec vagrant up --provider <provider>`
    Then the hostname "my-host.landrush-acceptance-test" should resolve to "10.10.10.123" on the host
    And the hostname "my-host.landrush-acceptance-test" should resolve to "10.10.10.123" on the guest
    And the hostname "my-host.landrush-acceptance-test" should resolve to "10.10.10.123" on the internal DNS server

    When I successfully run `bundle exec vagrant landrush set my-static-host.landrush-acceptance-test 42.42.42.42`
    Then the hostname "my-static-host.landrush-acceptance-test" should resolve to "42.42.42.42" on the internal DNS server
    And the hostname "my-static-host.landrush-acceptance-test" should resolve to "42.42.42.42" on the host
    And the hostname "my-static-host.landrush-acceptance-test" should resolve to "42.42.42.42" on the guest

    When I successfully run `bundle exec vagrant landrush set my-static-cname-host.landrush-acceptance-test my-static-host.landrush-acceptance-test`
    Then the hostname "my-static-cname-host.landrush-acceptance-test" should resolve to "42.42.42.42" on the internal DNS server
    And the hostname "my-static-cname-host.landrush-acceptance-test" should resolve to "42.42.42.42" on the host

    Examples:
      | box                           | provider   |
      | debian/jessie64               | virtualbox |
      #| opensuse/openSUSE-42.1-x86_64 | virtualbox |
      #| ubuntu/wily64                 | virtualbox |
