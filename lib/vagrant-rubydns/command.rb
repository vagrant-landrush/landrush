module VagrantRubydns
  class Command < Vagrant.plugin('2', :command)
    def execute
      puts "i am rubydns command"
      require_relative 'server'
      Server.run
      0
    end
  end
end
