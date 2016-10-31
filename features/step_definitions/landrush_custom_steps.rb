require 'landrush/server'

Then(/^the hostname "([^"]+)" should resolve to "([^"]+)" on the internal DNS server$/) do |host, ip|
  port = Landrush::Server.port
  resolver = Resolv::DNS.new(nameserver_port: [['localhost', port]], search: ['local'], ndots: 1)
  ip_resolved = resolver.getaddress(host).to_s
  expect(ip_resolved).to eq(ip)
end

Then(/^the hostname "([^"]+)" should resolve to "([^"]+)" on the host$/) do |host, ip|
  addrinfo = Addrinfo.getaddrinfo(host, nil, Socket::AF_INET)
  ip_resolved = addrinfo.first.ip_address
  expect(ip_resolved).to eq(ip)
end

Then(/^the hostname "([^"]+)" should resolve to "([^"]+)" on the guest/) do |host, ip|
  run("bundle exec vagrant ssh -c \"dig +short '#{host}' A\"")
  expect(last_command_started).to have_output(/^#{ip}$/)
end

Then(/^the host visible IP address of the guest is the IP of interface "([^"]+)"/) do |interface|
  cmd = "bundle exec vagrant ssh -c \"ip addr list #{interface} | grep 'inet ' | cut -d' ' -f6| cut -d/ -f1\""
  run(cmd)
  expect(last_command_started).to have_output(/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/)

  ip = last_command_started.output.split("\n").last

  run('bundle exec vagrant landrush list')

  expect(last_command_started).to have_output(/#{ip}$/)
end

Then(/^Landrush is( not)? running$/) do |negated|
  run('bundle exec vagrant landrush status')
  if negated
    expect(last_command_started).to have_output(/Daemon status: stopped/)
  else
    expect(last_command_started).to have_output(/Daemon status: running pid=[0-9]+/)
  end
end

Then(%r{^stdout from "([^"]*)" should( not)? match /(.*)/$}) do |cmd, negated, regexp|
  if negated
    aruba.command_monitor.find(Aruba.platform.detect_ruby(cmd)).send(:stdout) !~ /#{regexp}/
  else
    aruba.command_monitor.find(Aruba.platform.detect_ruby(cmd)).send(:stdout) =~ /#{regexp}/
  end
end
