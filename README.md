# Vagrant RubyDNS Plugin

Spins up a small RubyDNS server that you can point your VMs at, automatically
registers/deregisters IP addresseses of guests as they come up and down.

**Goal**: simple DNS that's visible on both the guest and the host

## Installation

Install under Vagrant (1.1 or later):

    $ vagrant plugin install vagrant-rubydns

## Usage

Spin up the DNS server

    $ vagrant rubydns

Bring up a machine that has a private network IP address and a hostname (see the `Vagrantfile` for an example) 

    $ vagrant up

And you should be able to get your hostname from your host:

    $ dig -p 10053 @localhost myhost.vagrant.dev

You can also make this visible to the guest by using the provisioner, which will set `resolv.conf` and `iptables` rules such that DNS points at our server:

    config.vm.provision :rubydns 

If you shut down your guest, the entries associated with it will be removed.

You can add static host entries to the DNS server in your Vagrantfile like so:

    config.rubydns.host 'myhost.example.com', '1.2.3.4'

Any DNS queries that do not match will be passed through to an upstream DNS server, so this will be able to serve as the one-stop shop for your guests' DNS needs.

## Work in Progress - Lots to do!

* The provisioner assumes resolv.conf-based DNS and iptables-based firewall.
* Lots of static values that need configurin' - config location, ports, etc.
* Tests tests tests.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
