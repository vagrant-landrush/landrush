require_relative '../../test_helper'

module Landrush
  module Cap
    module All
      describe ReadHostVisibleIpAddress do
        let(:landrush_ip_output) do
          <<YAML
- name: br-44ba74744d5d
  ipv4: 172.17.0.1
  ipv6: fe80::42:e1ff:fe01:ae98
- name: br-7884014b4104
  ipv4: 172.19.0.1
  ipv6: fe80::42:c0ff:fe4b:900c
- name: br-efce9da0c1fd
  ipv4: 172.18.0.1
  ipv6: fe80::42:2ff:fe46:f1d1
- name: docker0
  ipv4: 172.16.0.1
  ipv6: fe80::42:dbff:fe1b:6e92
- name: docker_gwbridge
  ipv4: 172.20.0.1
  ipv6: fe80::42:72ff:fe96:c6df
- name: enp4s0
  ipv4: 192.168.88.97
  ipv6: fe80::323d:9fa0:ef2a:ddf5
- name: wlp3s0
  ipv4: 192.168.88.118
  ipv6: fe80::6b80:15d4:e83c:a59d
- name: lo
  ipv4: 127.0.0.1
  ipv6: ::1/128
- name: veth050aa01
  ipv4: ""
  ipv6: fe80::c83a:8eff:fe7a:3244
- name: veth1c191f7
  ipv4: ""
  ipv6: fe80::b498:f3ff:fea1:3243
- name: veth38aa771
  ipv4: ""
  ipv6: fe80::8c97:e2ff:fe1a:b14f
- name: veth5f49498
  ipv4: ""
  ipv6: fe80::6825:20ff:fef5:a00d
- name: veth7803c65
  ipv4: ""
  ipv6: fe80::34d7:6cff:fe28:54ce
- name: veth8a09803
  ipv4: ""
  ipv6: fe80::b436:30ff:fed1:598e
- name: veth8bf1652
  ipv4: ""
  ipv6: fe80::60a8:67ff:fe85:cce4
- name: veth95ef8de
  ipv4: ""
  ipv6: fe80::9c45:e8ff:fe69:e62f
- name: vethc75f284
  ipv4: ""
  ipv6: fe80::78b2:7fff:fe55:59
- name: vethe533ef0
  ipv4: ""
  ipv6: fe80::b83e:93ff:fe52:aac7
YAML
        end

        let(:machine) { fake_machine }
        let(:addresses) { YAML.load(landrush_ip_output) }

        def call_cap(machine)
          Landrush::Cap::All::ReadHostVisibleIpAddress.read_host_visible_ip_address(machine)
        end

        before do
          # TODO: Is there a way to only unstub it for read_host_visible_ip_address?
          machine.guest.unstub(:capability)
          machine.guest.stubs(:capability).with(:landrush_ip_installed).returns(true)
          machine.guest.stubs(:capability).with(:landrush_ip_get).returns(addresses)

          machine.config.landrush.host_interface          = nil
          machine.config.landrush.host_interface_excludes = [/lo[0-9]*/, /docker[0-9]+/, /tun[0-9]+/, /br-(.+)/]
        end

        describe 'Issue 255: read_host_visible_ip_address failure in presence of interface without IPv4, with IPv6 address' do
          # Test IPv4
          it 'should return the last non-empty IPv4 address' do
            expected = addresses.detect { |a| a['name'] == 'wlp3s0' }
            expected = expected['ipv4']

            call_cap(machine).must_equal expected
          end

          # Test IPv6 selection
          it 'should return the last non-empty IPv6 address' do
            machine.config.landrush.host_interface_class = :ipv6

            expected = addresses.detect { |a| a['name'] == 'vethe533ef0' }
            expected = expected['ipv6']

            call_cap(machine).must_equal expected
          end

          # Test ANY selection
          it 'should return the last non-empty address of either class' do
            machine.config.landrush.host_interface_class = :any

            expected = addresses.detect { |a| a['name'] == 'vethe533ef0' }
            expected = expected['ipv6']

            call_cap(machine).must_equal expected
          end
        end
      end
    end
  end
end
