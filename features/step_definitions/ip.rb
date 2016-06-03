require 'landrush/server'

Then(/^the host visible IP address of the guest is the IP of interface "([^"]+)"/) do |interface|
  cmd = "vagrant ssh -c \"ip addr list #{interface} | grep 'inet ' | cut -d' ' -f6| cut -d/ -f1\""
  run(cmd)
  expect(last_command_started).to have_output(/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/)

  ip = last_command_started.output.split("\n").last

  run('vagrant landrush list')

  expect(last_command_started).to have_output(/#{ip}$/)
end
