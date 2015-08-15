require 'vagrant/util/retryable'

module Landrush
  class Ip
    include Landrush::Action::Common
    include Vagrant::Util::Retryable

    #
    # Constructor. Takes a machine and a path of where to put the binary
    #
    def initialize(machine, path)
      @machine   = machine
      @path      = path
      @error     = nil

      #
      # These are the platforms and architectures supported by the binary
      # They are not necessarily supported as a Guest OS in Vagrant (yet).
      #
      @platforms = {
        :darwin  => %w(386 amd64),
        :openbsd => %w(386 amd64),
        :freebsd => %w(386 amd64 arm),
        :netbsd  => %w(386 amd64 arm),
        :linux   => %w(386 amd64 arm),
        :windows => %w(386 amd64),
        :plan9   => %w(386),
      }
    end

    def info(msg)
      # This isn't the correct way, but I'm not sure what the correct pattern is!
      @machine.env.ui.info "[landrush-ip] #{msg}"
    end

    def error
      @error
    end

    #
    # This installs landrush-ip.
    #
    # landrush-ip is small binary written in GoLang that iterates over all network interfaces.
    # This binary is available for all platforms and behaves the same on all of them.
    #
    # By default, it behaves the same as hostname -I does on UNIX systems; it dumps every interface's IP.
    # It however also allows us to filter out a specific interface.
    #
    def install(platform = nil, arch = nil)
      # Check what platform we're on
      if platform.nil?
        @machine.guest.capability_host_chain.each do |os|
          next unless @platforms.has_key?(os[0].to_s.to_sym)

          platform = os[0].to_s.to_sym
        end
      end

      if platform.nil? or !@platforms.has_key?(platform)
        @error = "Unsupported guest platform: #{platform}"

        return false
      end

      # Now let's check the architecture
      if arch.nil?
        case platform
        when :windows
          #
          # See:
          # - http://superuser.com/a/293143
          # - http://blogs.msdn.com/b/david.wang/archive/2006/03/26/howto-detect-process-bitness.aspx
          #
          # Quicker than using systeminfo and works from XP and up.
          #
          script = <<-EOH
            set Arch=x64
            if "%PROCESSOR_ARCHITECTURE%" == "x86" (
                if not defined PROCESSOR_ARCHITEW6432 set Arch=x86
            )
            echo %Arch%
          EOH

          result = ''
          @machine.communicate.execute(script) do |type, data|
            result << data if type == :stdout
          end

          if result =~ /(x64)/i
            arch = 'amd64'
          elsif result =~ /(x86)/i
            arch = '386'
          end
        else
          #
          # Windows aside, every supported UNIX flavour includes uname
          # For once there's a UNIX tool that actually behaves relatively consistently across platforms.
          #
          result = ''
          @machine.communicate.execute('uname -mrs') do |type, data|
            result << data if type == :stdout
          end

          #
          # uname -mrs will return the following architectures:
          # i386 i686 x86_64 ia64 alpha amd64 arm armeb armel hppa m32r m68k
          # mips mipsel powerpc ppc64 s390 s390x sh3 sh3eb sh4 sh4eb sparc
          #
          # The vast majority are irrelevant to us.
          #
          if result =~ /(x86_64|ia64|amd64)/i
            arch = 'amd64'
          elsif result =~ /(arm)/i
            arch = 'arm'
          elsif result =~ /(i386|i686)/i
            arch = '386'
          end
        end
      end

      if arch.nil? or !@platforms[platform].include?(arch)
        @error = "Unsupported guest architecture: #{arch} (#{platform})"

        return false
      end

      # We've got platform and architecture now
      info "Platform: #{platform}/#{arch}"

      @machine.communicate.tap do |comm|
        ssh_info = nil
        retryable(on: Vagrant::Errors::SSHNotReady, tries: 3, sleep: 2) do
          ssh_info = @machine.ssh_info
          raise Vagrant::Errors::SSHNotReady if ssh_info.nil?
        end

        host_path = @machine.env.tmp_path.join("#{@machine.id}-landrush-ip")
        host_path.delete if host_path.file?

        begin
          http             = Net::HTTP.new('api.github.com', 443)
          http.use_ssl     = true
          http.verify_mode = OpenSSL::SSL::VERIFY_PEER

          response = http.request(Net::HTTP::Get.new('/repos/werelds/landrush-ip/releases/latest'))
          result   = JSON.parse(response.body)

          release_url = nil
          unless result['assets'].nil?
            result['assets'].each do |asset|
              if asset['name'] == "#{platform}_#{arch}_landrush-ip"
                release_url = asset['browser_download_url']

                break
              end
            end
          end

          if release_url.nil?
            @error = 'No suitable version of landrush-ip found'

            return false
          end

          info "Using #{release_url}"
          Vagrant::Util::Downloader.new(release_url, host_path).download!

          comm.upload(host_path, @path)
          comm.sudo("chown -R #{ssh_info[:username]} #{@path}", error_check: false)
          comm.sudo("chmod +x #{@path}", error_check: false)
        ensure
          host_path.delete if host_path.file?
        end

        return true
      end
    end
  end
end
