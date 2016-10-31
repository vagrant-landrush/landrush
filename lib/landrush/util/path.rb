module Landrush
  module Util
    class Path
      def self.embedded_vagrant_ruby
        bin_dir = embedded_vagrant_bin_dir
        ruby_bin = bin_dir + separator + 'ruby'
        ruby_bin if File.exist?(ruby_bin)
      end

      def self.ensure_ruby_on_path
        bin_dir = embedded_vagrant_bin_dir
        ENV['PATH'] = bin_dir + File::PATH_SEPARATOR + ENV['PATH'] if File.exist?(bin_dir)
      end

      def self.embedded_vagrant_bin_dir
        vagrant_binary = Vagrant::Util::Which.which('vagrant')
        vagrant_binary = File.realpath(vagrant_binary) if File.symlink?(vagrant_binary)
        # in a Vagrant installation the Ruby executable is in ../embedded/bin relative to the vagrant executable
        File.dirname(File.dirname(vagrant_binary)) + separator + 'embedded' + separator + 'bin'
      end

      def self.separator
        # we don't use File.join here, since even on Cygwin we want a Windows path - see https://github.com/vagrant-landrush/landrush/issues/237
        if Vagrant::Util::Platform.windows?
          '\\'
        else
          '/'
        end
      end
    end
  end
end
