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
          command = "ifconfig  | grep 'inet addr:' | grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1 }'"
          result  = ""
          machine.communicate.execute(command) do |type, data|
            result << data if type == :stdout
          end

          result.chomp.split("\n").last
        end
      end
    end
  end
end
