module VagrantRubydns
  class Command < Vagrant.plugin('2', :command)
    def execute
      require_relative 'server'
      Server.run
      0
    end
  end
end
