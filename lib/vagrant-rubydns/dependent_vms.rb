require 'fileutils'

#
# Keep track of dependent VMs.
#
# Poor man's race condition defense - touch and rm files in a directory and count them.
#
module VagrantRubydns
  class DependentVMs
    extend Enumerable

    def self.each(&block)
      (dir.directory? ? dir.children : []).each(&block)
    end

    def self.add(machine)
      FileUtils.touch(file_for(machine))
    end

    def self.remove(machine)
      file_for(machine).tap { |f| f.delete if f.exist? }
    end

    def self.list
      self.map { |path| path.basename.to_s }
    end

    def self.clear!
      dir.rmtree
    end

    def self.file_for(machine)
      dir.join(Util.hostname(machine))
    end

    def self.dir
      VagrantRubydns.working_dir.join('dependent_vms').tap(&:mkpath)
    end
  end
end
