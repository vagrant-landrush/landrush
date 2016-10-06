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

    When I successfully run `bundle exec vagrant reload`
    Then Landrush is running

    Examples:
      | box             | provider   |
      | debian/jessie64 | virtualbox |
