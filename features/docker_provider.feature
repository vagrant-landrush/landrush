Feature: Landrush with Docker provider
  Landrush should work with Docker provider

  Scenario: Booting box with Docker provider
    Given a file named "Vagrantfile" with:
    """
    Vagrant.configure(2) do |config|
      config.vm.provider "docker" do |d|
        # https://github.com/tknerr/vagrant-docker-baseimages
        d.image = "tknerr/baseimage-ubuntu:18.04"
        d.has_ssh = true
        d.privileged = true
      end

      config.vm.provision "shell", inline: 'apt-get install -y net-tools dnsutils'

      config.landrush.enabled = true
      config.vm.hostname = "foo.vagrant.test"

      config.landrush.host 'static1.example.com', '1.2.3.4'
      config.landrush.host 'static2.example.com', '2.3.4.5'
    end
    """
    When I successfully run `bundle exec vagrant up`
    Then Landrush is running

    When I successfully run `bundle exec vagrant ssh -- dig +noall +answer +nocomments static1.example.com`
    Then stdout from "bundle exec vagrant ssh -- dig +noall +answer +nocomments static1.example.com" should match /.*1\.2\.3\.4/

    When I successfully run `bundle exec vagrant landrush stop`
    Then Landrush is not running

