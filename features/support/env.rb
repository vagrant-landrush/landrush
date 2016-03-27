require 'aruba/cucumber'
require 'komenda'

Aruba.configure do |config|
  config.exit_timeout = 300
  config.activate_announcer_on_command_failure = [:stdout, :stderr]
end

After do |_scenario|
  if File.exist?(File.join(aruba.config.working_directory, 'Vagrantfile'))
    result = Komenda.run('vagrant destroy -f', cwd: aruba.config.working_directory)
    fail "Unable to destroy vagrant environment:\n#{result.output}" unless result.success?
  end
end
