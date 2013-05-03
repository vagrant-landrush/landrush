require 'rubydns'

module VagrantRubydns
  class Server < RExec::Daemon::Base

    INTERFACES = [
      [:udp, "0.0.0.0", 10053],
      [:tcp, "0.0.0.0", 10053]
    ]
    Name = Resolv::DNS::Name
    IN = Resolv::DNS::Resource::IN

    def self.upstream
      @upstream ||= RubyDNS::Resolver.new([[:udp, "8.8.8.8", 53], [:tcp, "8.8.8.8", 53]])
    end

    def self.logfile
      VagrantRubydns.working_dir.join('server.log')
    end

    # For RExec
    @@base_directory = VagrantRubydns.working_dir

    def self.running?
      RExec::Daemon::ProcessFile.status(self) == :running
    end

    def self.run
      server = self
      RubyDNS::run_server(:listen => INTERFACES) do
        self.logger.level = Logger::INFO
        
        match(/.*/, IN::A) do |transaction|
          ip = Store.hosts.get(transaction.name)
          if ip
            transaction.respond!(ip)
          else
            transaction.passthrough!(server.upstream)
          end
        end

        # Default DNS handler
        otherwise do |transaction|
          transaction.passthrough!(server.upstream)
        end
      end
    end
  end
end
