Then(/^the hostname "([^"]+)" should resolve to "([^"]+)" on the internal DNS server$/) do |host, ip|
  run("dig +short @localhost -p 10053 '#{host}' A")
  expect(last_command_started).to have_output(/^#{ip}$/)
end

Then(/^the hostname "([^"]+)" should resolve to "([^"]+)" on the host$/) do |host, ip|
  if RbConfig::CONFIG['host_os'] =~ /darwin|mac os/
    run('sudo killall -HUP mDNSResponder')
    run("ping -c 1 -t 1 '#{host}'")
    expect(last_command_started).to have_output(/\(#{ip}\)/)
  else
    run("dig +short '#{host}' A")
    expect(last_command_started).to have_output(/^#{ip}$/)
  end
end

Then(/^the hostname "([^"]+)" should resolve to "([^"]+)" on the guest/) do |host, ip|
  run("vagrant ssh -c \"dig +short '#{host}' A\"")
  expect(last_command_started).to have_output(/^#{ip}$/)
end
