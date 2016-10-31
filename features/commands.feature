Feature: Landrush reload
  Landrush DNS server should restart on a 'vagrant reload'

  Scenario Outline: booting a box and restarting it
    Given a file named "Vagrantfile" with:
    """
    Vagrant.configure("2") do |config|
      config.vm.box = '<box>'
      config.vm.synced_folder '.', '/vagrant', disabled: true
      config.landrush.enabled = true
    end
    """
    When I successfully run `bundle exec vagrant up --provider <provider>`
    Then Landrush is running

    When I successfully run `bundle exec vagrant landrush set foo 1.2.3.4`
    And I successfully run `bundle exec vagrant landrush set bar 4.3.1.1`
    And I successfully run `bundle exec vagrant landrush ls`
    Then stdout from "bundle exec vagrant landrush ls" should match /^foo.*1.2.3.4$/
    Then stdout from "bundle exec vagrant landrush ls" should match /^bar.*4.3.2.1$/

    When I successfully run `bundle exec vagrant landrush rm --all`
    And I successfully run `bundle exec vagrant landrush ls`
    Then stdout from "bundle exec vagrant landrush ls" should match /^foo.*1.2.3.4$/
    Then stdout from "bundle exec vagrant landrush ls" should match /^bar.*4.3.2.1$/

    When I successfully run `bundle exec vagrant reload`
    Then Landrush is running

    When I successfully run `bundle exec vagrant landrush stop`
    Then Landrush is not running

    Examples:
      | box             | provider   |
      | debian/jessie64 | virtualbox |
