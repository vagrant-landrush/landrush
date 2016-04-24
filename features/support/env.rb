require 'aruba/cucumber'
require 'komenda'

Aruba.configure do |config|
  config.exit_timeout = 300
  config.activate_announcer_on_command_failure = [:stdout, :stderr]
end

After do |_scenario|
  Komenda.run('bundle exec vagrant landrush stop', fail_on_fail: true)

  if File.exist?(File.join(aruba.config.working_directory, 'Vagrantfile'))
    Komenda.run('bundle exec vagrant destroy -f', cwd: aruba.config.working_directory, fail_on_fail: true)
  end
end
