# Landrush: DNS for Vagrant

Simple DNS that's visible on both the guest and the host.

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

Bring up a machine that has a hostname set (see the `Vagrantfile` for an example)

    $ vagrant up

And you should be able to get your hostname from your host:

    $ dig -p 10053 @localhost myhost.vagrant.dev

If you shut down your guest, the entries associated with it will be removed.

### Static entries

You can add static host entries to the DNS server in your `Vagrantfile` like so:

    config.landrush.host 'myhost.example.com', '1.2.3.4'

This is great for overriding production services for nodes you might be testing locally. For example, perhaps you might want to override the hostname of your puppetmaster to point to a local vagrant box instead.

### Wildcard Subdomains

For your convenience, any subdomain of a DNS entry known to landrush will resolve to the same IP address as the entry. For example: given `myhost.vagrant.dev -> 1.2.3.4`, both `foo.myhost.vagrant.dev` and `bar.myhost.vagrant.dev` will also resolve to `1.2.3.4`.

### Unmatched Queries

Any DNS queries that do not match will be passed through to an upstream DNS server, so this will be able to serve as the one-stop shop for your guests' DNS needs.

### Visibility on the Guest

Linux guests should automatically have their DNS traffic redirected via `iptables` rules to the Landrush DNS server. File an issue if this does not work for you.

### Visibility on the Host

If you're on an OS X host, we use a nice trick to unobtrusively add a secondary DNS server only for specific domains.

Similar behavior can theoretically be achieved on Linux hosts with `dnsmasq`; hopefully sometime in the near future this project will support visibility on linux hosts too!

### Additional CLI commands

Check out `vagrant landrush` for additional commands to monitor the DNS server daemon.

## Help Out!

This project could use your feedback and help! Please don't hesitate to open issues or submit pull requests. NO HESITATION IS ALLOWED. NONE WHATSOEVER.

