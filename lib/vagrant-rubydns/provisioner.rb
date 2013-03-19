module VagrantRubydns
  class Provisioner < Vagrant.plugin('2', :provisioner)
    def initialize(machine, config)
      super
    end

    def configure(root_config)
    end

    def provision
      # hostname, ip_address = Util.host_and_ip(@machine)
      # Config.set(hostname, ip_address)

      @machine.env.ui.info "setting up machine's DNS to point to our server"

      redirect_dns_to_unpriviledged_port_tcp = 'OUTPUT -t nat -d 10.0.2.2 -p tcp --dport 53 -j DNAT --to-destination 10.0.2.2:10053'
      command = %Q(iptables -C #{redirect_dns_to_unpriviledged_port_tcp} 2> /dev/null || iptables -A #{redirect_dns_to_unpriviledged_port_tcp})
      _run_command(command)

      redirect_dns_to_unpriviledged_port_udp = 'OUTPUT -t nat -d 10.0.2.2 -p udp --dport 53 -j DNAT --to-destination 10.0.2.2:10053'
      command = %Q(iptables -C #{redirect_dns_to_unpriviledged_port_udp} 2> /dev/null || iptables -A #{redirect_dns_to_unpriviledged_port_udp})
      _run_command(command)

      command = %q(sed -i'' -e 's/10.0.2.3/10.0.2.2/' /etc/resolv.conf)
      _run_command(command)
    end

    def _run_command(command)
      @machine.communicate.sudo(command) do |data, type|
        if [:stderr, :stdout].include?(type)
          color = (type == :stdout) ? :green : :red
          @machine.env.ui.info(data.chomp, :color => color, :prefix => false)
        end
      end
    end
  end
end
