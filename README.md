# Vagrant RubyDNS Plugin

Simple DNS that's visible on both the guest and the host.

Spins up a small RubyDNS server that you can point your VMs at, automatically
registers/deregisters IP addresseses of guests as they come up and down.


## Installation

Install under Vagrant (1.1 or later):

    $ vagrant plugin install vagrant-rubydns

## Usage

Enable the plugin in your `Vagrantfile`:

    config.rubydns.enable

Bring up a machine that has a private network IP address and a hostname (see the `Vagrantfile` for an example) 

    $ vagrant up

And you should be able to get your hostname from your host:

    $ dig -p 10053 @localhost myhost.vagrant.dev
    
If you shut down your guest, the entries associated with it will be removed.

You can add static host entries to the DNS server in your `Vagrantfile` like so:

    config.rubydns.host 'myhost.example.com', '1.2.3.4'

Any DNS queries that do not match will be passed through to an upstream DNS server, so this will be able to serve as the one-stop shop for your guests' DNS needs.

### Visibility on the Guest

You can also make this visible to the guest by using the provisioner, which will set `resolv.conf` and `iptables` rules such that DNS points at our server:

    config.vm.provision :rubydns 

### Visibility on the Host

I'm currently developing this on OS X 10.8, and there's a nice trick you can pull to unobtrusibly add a secondary DNS server only for specific domains.

All you do is drop a file in `/etc/resolvers/$DOMAIN` with information on how to connect to the DNS server you'd like to use for that domain.

So what I do is name all of my vagrant servers with the pattern `$host.vagrant.dev` and then drop a file called `/etc/resolvers/vagrant.dev` with these contents:

```
# Use vagrant-rubydns server for this domain
nameserver 127.0.0.1
port 10053
```

This gives us automatic access to the vagrant-rubydns hosts without having to worry about it getting in the way of our normal DNS config.

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
