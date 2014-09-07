# Landrush: DNS for Vagrant [![Build Status](https://travis-ci.org/phinze/landrush.png)](https://travis-ci.org/phinze/landrush)

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

    config.landrush.enabled = true

Bring up a machine.

    $ vagrant up

And you should be able to get your hostname from your host:

    $ dig -p 10053 @localhost myhost.vagrant.dev

If you shut down your guest, the entries associated with it will be removed.

Landrush assigns your vm's hostname from either the vagrant config (see the `examples/Vagrantfile`) or system's actual hostname by running the `hostname` command. A default of "guest-vm" is assumed if hostname is otherwise not available.

### Dynamic entries

Every time a VM is started, its IP address is automatically detected and a DNS record is created that maps the hostname to its IP.

If for any reason the auto-detection detects no IP address or the wrong IP address, or you want to override it, you can do like so:

    config.landrush.host_ip_address = '1.2.3.4'

If you are using a multi-machine `Vagrantfile`, configure this inside each of your `config.vm.define` sections.

### Static entries

You can add static host entries to the DNS server in your `Vagrantfile` like so:

    config.landrush.host 'myhost.example.com', '1.2.3.4'

This is great for overriding production services for nodes you might be testing locally. For example, perhaps you might want to override the hostname of your puppetmaster to point to a local vagrant box instead.

### Wildcard Subdomains

For your convenience, any subdomain of a DNS entry known to landrush will resolve to the same IP address as the entry. For example: given `myhost.vagrant.dev -> 1.2.3.4`, both `foo.myhost.vagrant.dev` and `bar.myhost.vagrant.dev` will also resolve to `1.2.3.4`.

If you would like to configure your guests to be accessible from the host as subdomains of something other than the default `vagrant.dev`, you can use the `config.landrush.tld` option in your Vagrantfile like so:

    config.landrush.tld = 'vm'

Note that from the __host__, you will only be able to access subdomains of your configured TLD by default- so wildcard subdomains only apply to that space. For the __guest__, wildcard subdomains work for anything.

### Unmatched Queries

Any DNS queries that do not match will be passed through to an upstream DNS server, so this will be able to serve as the one-stop shop for your guests' DNS needs.

If you would like to configure your own upstream servers, add upstream entries to your `Vagrantfile` like so:

    config.landrush.upstream '10.1.1.10'
    # Set the port to 1001
    config.landrush.upstream '10.1.2.10', 1001
    # If your upstream is TCP only for some strange reason
    config.landrush.upstream '10.1.3.10', 1001, :tcp

### Visibility on the Guest

Linux guests should automatically have their DNS traffic redirected via `iptables` rules to the Landrush DNS server. File an issue if this does not work for you.

To disable this functionality:

    config.landrush.guest_redirect_dns = false

You may want to do this if you are already proxying all your DNS requests through your host (e.g. using VirtualBox's natdnshostresolver1 option) and you
have DNS servers that you can easily set as upstreams in the daemon (e.g. DNS requests that go through the host's VPN connection).

### Visibility on the Host

If you're on an OS X host, we use a nice trick to unobtrusively add a secondary DNS server only for specific domains.

Similar behavior can be achieved on Linux hosts with `dnsmasq`. You can integrate Landrush with dnsmasq on Ubuntu like so (tested on Ubuntu 13.10):

    sudo apt-get install -y resolvconf dnsmasq
    sudo sh -c 'echo "server=/vagrant.dev/127.0.0.1#10053" > /etc/dnsmasq.d/vagrant-landrush'
    sudo service dnsmasq restart

If you use a TLD other than the default `vagrant.dev`, replace the TLD in the above instructions accordingly. Please be aware that anything ending in '.local' as TLD will not work because the `avahi` daemon reserves this TLD for its own uses.

### Visibility on other Devices (phone)

You might want to resolve Landrush's DNS-entries on *additional* computing devices, like a mobile phone.

Please refer to [/doc/proxy-mobile](/doc/proxy-mobile) for instructions.

### Additional CLI commands

Check out `vagrant landrush` for additional commands to monitor the DNS server daemon.

## Help Out!

This project could use your feedback and help! Please don't hesitate to open issues or submit pull requests. NO HESITATION IS ALLOWED. NONE WHATSOEVER.

