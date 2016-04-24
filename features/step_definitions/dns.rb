require 'landrush/server'

Then(/^the hostname "([^"]+)" should resolve to "([^"]+)" on the internal DNS server$/) do |host, ip|
  port = Landrush::Server.port
  resolver = Resolv::DNS.new(:nameserver_port => [['localhost', port]], :search => ['local'], :ndots => 1)
  ip_resolved = resolver.getaddress(host).to_s
  expect(ip_resolved).to eq(ip)
end

Then(/^the hostname "([^"]+)" should resolve to "([^"]+)" on the host$/) do |host, ip|
  addrinfo = Addrinfo.getaddrinfo(host, nil, Socket::AF_INET)
  ip_resolved = addrinfo.first.ip_address
  expect(ip_resolved).to eq(ip)
end

Then(/^the hostname "([^"]+)" should resolve to "([^"]+)" on the guest/) do |host, ip|
  run("vagrant ssh -c \"dig +short '#{host}' A\"")
  expect(last_command_started).to have_output(/^#{ip}$/)
end
