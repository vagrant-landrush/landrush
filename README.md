# Landrush: DNS for Vagrant

Simple DNS that's visible on both the guest and the host.

> Because even a Vagrant needs a place to settle down once in a while.

Spins up a small DNS server and redirects DNS traffic from your VMs to use it,
automatically registers/deregisters IP addresseses of guests as they come up
and down.

## Installation

Install under Vagrant (1.1 or later):

    $ vagrant plugin install landrush

## Usage

### Get started

Enable the plugin in your `Vagrantfile`:

    config.landrush.enable

Bring up a machine that has a private network IP address and a hostname (see the `Vagrantfile` for an example)

    $ vagrant up

And you should be able to get your hostname from your host:

    $ dig -p 10053 @localhost myhost.vagrant.dev

If you shut down your guest, the entries associated with it will be removed.


### Static entries

You can add static host entries to the DNS server in your `Vagrantfile` like so:

    config.landrush.host 'myhost.example.com', '1.2.3.4'

This is great for overriding production services for nodes you might be testing locally. For example, perhaps you might want to override the hostname of your puppetmaster to point to a local vagrant box instead.

### Unmatched Queries

Any DNS queries that do not match will be passed through to an upstream DNS server, so this will be able to serve as the one-stop shop for your guests' DNS needs.

### Visibility on the Guest

Linux guests using iptables should automatically have their DNS traffic redirected properly to our DNS server. File an issue if this does not work for you.

### Visibility on the Host

If you're on an OS X host, we can use a nice trick to unobtrusibly add a secondary DNS server only for specific domains.

If you name all of my vagrant servers with the pattern `$host.vagrant.dev` and then drop a file called `/etc/resolver/vagrant.dev` with these contents:

```
# Use landrush server for this domain
nameserver 127.0.0.1
port 10053
```

Once you have done this, you can run `scutil --dns` to confirm that the DNS resolution is working -- you should see something like:
```
resolver #8
  domain   : vagrant.dev
  nameserver[0] : 127.0.0.1
  port     : 10053
```

This gives us automatic access to the landrush hosts without having to worry about it getting in the way of our normal DNS config.

There's also a handy command to automate the creation of this file:

```
vagrant landrush install
```

### Additional CLI commands

Check out `vagrant landrush` for additional commands to monitor the DNS server daemon.

## Work in Progress - Lots to do!

* The guest visibility strategy assumes iptables-based firewall.
* Lots of static values that need configurin' - config location, ports, etc.
* Tests tests tests.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
