module Landrush
  module Cap
    module Linux
      module ReadHostVisibleIpAddress
        #
        # !!!!!!!!!!!!
        # !!  NOTE  !!
        # !!!!!!!!!!!!
        #
        # This is a fragile heuristic: we are simply assuming the IP address of
        # the last interface non-localhost IP address is the host-visible one.
        #
        # For VMWare, the interface that Vagrant uses is host accessible, so we
        # expect this to be the same as `read_ip_address`.
        #
        # For VirtualBox, the Vagrant interface is not host visible, so we add
        # our own private_network, which we expect this to return for us.
        #
        # If the Vagrantfile sets up any sort of fancy networking, this has the
        # potential to fail, which will break things.
        #
        # TODO: Find a better heuristic for this implementation.
        #
        def self.read_host_visible_ip_address(machine)
          landrush_ip = Landrush::Ip.new(machine, '/usr/local/bin/landrush-ip')

          if landrush_ip.install
            cmd = '/usr/local/bin/landrush-ip'

            unless machine.config.landrush.exclude.nil?
              [*machine.config.landrush.exclude].each do |iface|
                cmd << " -exclude '#{iface}'"
              end
            end

            unless machine.config.landrush.interface.nil?
              cmd << " #{machine.config.landrush.interface}"
            end
          else
            machine.env.ui.warn('Warning, unable to install landrush-ip on guest, falling back to `hostname -I`')
            cmd = command
          end

          result = ''
          machine.communicate.execute(cmd) do |type, data|
            result << data if type == :stdout
          end

          last_line = result.chomp.split("\n").last || ''
          addresses = last_line.split(/\s+/).map { |address| IPAddr.new(address) }
          addresses = addresses.reject { |address| address.ipv6? }

          if addresses.empty?
            raise "Cannot detect IP address, command `#{cmd}` returned `#{result}`"
          end

          addresses.last.to_s
        end

        def self.command
          'hostname -I'
        end
      end
    end
  end
end
