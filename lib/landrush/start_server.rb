# This file gets execute outside the Vagrant (bundled) environment.
# For that reason we have to put the gems we need ourself onto the LOADPATH.
# The caller of this file will pass the Vagrant gem dir as first argument which
# we use as base to find the required gems

gem_path = ARGV[2]
Dir.entries(gem_path).each { |gem_dir| $LOAD_PATH.unshift "#{File.join(ARGV[2], gem_dir)}/lib" }

require_relative 'server'

Landrush::Server.run(ARGV[0], ARGV[1]) if __FILE__ == $PROGRAM_NAME
