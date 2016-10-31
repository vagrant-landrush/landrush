require 'aruba/cucumber'
require 'komenda'
require 'fileutils'
require 'find'

Aruba.configure do |config|
  config.exit_timeout = 3600
  config.activate_announcer_on_command_failure = [:stdout, :stderr]
  config.working_directory = 'build/aruba'
end

Before do |_scenario|
  # Making sure that all tests run in a pristine environment
  # Create the Vagrant home directory for the tests
  vagrant_home = File.join(File.dirname(__FILE__), '..', '..', 'build', 'vagrant.d')
  # Make sure the Vagrant home directory is "clean".
  # We keep the boxes directory to not have to re-download the boxes each time
  ENV['VAGRANT_HOME'] = vagrant_home
  Dir.new(ENV['VAGRANT_HOME']).entries.reject { |file| 'boxes'.eql?(file) || '.'.eql?(file) || '..'.eql?(file) }
     .each { |file| FileUtils.rmtree(File.join(ENV['VAGRANT_HOME'], file)) }

  # Actual gems are in ~/vagrant.d/gems/gems
  gems_path = File.join(vagrant_home, 'gems', 'gems')
  FileUtils.mkdir_p gems_path

  # Find the path to the Bundler gems
  bundler_gem_path = File.join(Bundler.rubygems.find_name('bundler').first.base_dir, 'gems')

  # Copy the gems to the Vagrant gems dir
  FileUtils.cp_r bundler_gem_path, gems_path, verbose: false
end

After do |_scenario|
  Komenda.run('bundle exec vagrant landrush stop', fail_on_fail: true)

  # If there is a Vagrantfile from previous run, delete it
  if File.exist?(File.join(aruba.config.working_directory, 'Vagrantfile'))
    Komenda.run('bundle exec vagrant destroy -f', cwd: aruba.config.working_directory, fail_on_fail: true)
  end
end
