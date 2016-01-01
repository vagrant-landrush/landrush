# Resolve Landrush-entries on a mobile device

For your mobile phone to access VM-hosts two conditions need to be met:
- Your VM *needs to be accessible* from the network your phone's on (configure a [public network](http://docs.vagrantup.com/v2/networking/public_network.html)).
- The phone should query Landrush to resolve DNS entries.

Most smartphones allow you to configure a custom DNS server (instructions further below).
But unfortunately some don't allow you to configure a DNS server running on port 10053.

To work around that one can proxy queries to the default port 53 with a system-wide DNS server to Landrush.

## Proxy bind to your landrush server
The DNS-server `bind` can be installed with [homebrew](http://brew.sh/) on OS X.

In its configuration file forward all queries to your local Landrush and disable caching:

    options {
        directory "/usr/local/var/named";

        forwarders {
            127.0.0.1 port 10053;
        };

        max-cache-ttl 0;
        max-ncache-ttl 0;
    };


After restarting bind you should be able to resolve your VM's entries on your local default DNS server (port 53):

    $ dig -p 53 @localhost myhost.vagrant.test

## Configure DNS server on your mobile phone
Set your bind server's IP address as the DNS server on your external device.

**How to set the DNS server on iOS:**

1. Open *Settings* > *Wi-Fi*
2. Tap the *i*-icon next to your network
3. Tap the *DNS*-row and edit the value

**How to set the DNS server on Android:**

1. Open *Settings* > *Wi-Fi*
2. Tap and hold your network, then chose *Modify network*
3. Check *Show advanced options*
4. Under *IP Settings* tap *DHCP / Static* and change the value to *Static*
5. Change the *DNS 1* value and tap *Save*

Or use the [Dns Changer](https://play.google.com/store/apps/details?id=net.emrekoc.dnschanger) application.
