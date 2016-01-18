require 'fileutils'

#
# Keep track of dependent VMs.
#
# Poor man's race condition defense - touch and rm files in a directory and count them.
#
module Landrush
  class DependentVMs
    extend Enumerable

    def self.each(&block)
      (dir.directory? ? dir.children : []).each(&block)
    end

    def self.add(hostname)
      FileUtils.touch(file_for(hostname))
    end

    def self.remove(hostname)
      file_for(hostname).tap { |f| f.delete if f.exist? }
    end

    def self.list
      map { |path| path.basename.to_s }
    end

    def self.clear!
      dir.rmtree
    end

    def self.file_for(hostname)
      dir.join(hostname)
    end

    def self.dir
      Server.working_dir.join('dependent_vms').tap(&:mkpath)
    end
  end
end
