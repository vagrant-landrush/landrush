## Unreleased

- Issue [#249](https://github.com/vagrant-landrush/landrush/issues/249) - Spawned DNS server holds vagrant executable's stderr, stdout open
- PR [#243](https://github.com/vagrant-landrush/landrush/pull/243) - Vagrant would print error message "The system cannot find the path

## [1.1.1] - 2016-08-07

- Issue [#241](https://github.com/vagrant-landrush/landrush/issues/241) - Action::Teardown is not called for providers other than VirtualBox
- Issue [#239](https://github.com/vagrant-landrush/landrush/issues/239) - Add support for HyperV 
- Issue [#237](https://github.com/vagrant-landrush/landrush/issues/237) - Landrush::Server.ensure_ruby_on_path should not be using File.join
- Issue [#236](https://github.com/vagrant-landrush/landrush/issues/236) - Explicitly call landrush_ip_installed and landrush_ip_install 

## [1.1.0] - 2016-08-05

- Issue [#234](https://github.com/vagrant-landrush/landrush/issues/234) - sed command in RestartDnsmasq for redhat hosts does insert 127.0.0.1
- Issue [#231](https://github.com/vagrant-landrush/landrush/issues/231) - Make sure that there is alway a ruby binary on the path
- Issue [#233](https://github.com/vagrant-landrush/landrush/issues/233) - Wrong sudo command in ConfigureVisibilityOnHost for OS X bug
- Issue [#229](https://github.com/vagrant-landrush/landrush/issues/229) - ConfigureVisibilityOnHost exist main execution when not in admin mode
- Issue [#226](https://github.com/vagrant-landrush/landrush/issues/226) - Landrush::Cap::Linux::ConfigureVisibilityOnHost accesses capabilties the wrong way
- Issue [#225](https://github.com/vagrant-landrush/landrush/issues/225) - Windows host configuration fails starting the Wired AutoConfig service
- Issue [#223](https://github.com/vagrant-landrush/landrush/issues/223) - The wrong TLD is used for the darwin host capabiltiy configure_visibility_on_host bug
- Issue [#215](https://github.com/vagrant-landrush/landrush/issues/215) - Document issues with upstream DNS server configuration in VPN settings documentation
- Issue [#211](https://github.com/vagrant-landrush/landrush/issues/211) - Provide automatic host visibility configuration on Linux feature
- Issue [#202](https://github.com/vagrant-landrush/landrush/issues/202) - Landrush kill not working in Windows environment
- Issue [#209](https://github.com/vagrant-landrush/landrush/issues/209) - Remove issues directory
- Issue [#190](https://github.com/vagrant-landrush/landrush/issues/190) - Add `sudoers` rules to README to support passwordless provisioning
- Issue [#176](https://github.com/vagrant-landrush/landrush/issues/176) - Can't create cname in Vagrantfile
- Issue [#171](https://github.com/vagrant-landrush/landrush/issues/171) - Provide automatic host visibility configuration on Windows
- Issue [#201](https://github.com/vagrant-landrush/landrush/issues/201) - Upgrade to Vagrant 1.8.4 as development version build
- Issue [#189](https://github.com/vagrant-landrush/landrush/issues/189) - Improve IP determination by using config information guest-ip-detection
- Issue [#199](https://github.com/vagrant-landrush/landrush/issues/199) - Switch to win32-process for creating sub processes on Windows bug
- Issue [#114](https://github.com/vagrant-landrush/landrush/issues/114) - Make IP determination platform-agnostic and a bit more flexible enhancement guest-ip-detection
- Issue [#196](https://github.com/vagrant-landrush/landrush/issues/196) - gem spec refers to old repo

## [1.0.0] - 2016-05-18

- Added: Acceptance CI tests ([#136](https://github.com/vagrant-landrush/landrush/issues/136))
- Fixed: Making sure that the right Vagrant data dir is used ([#157](https://github.com/vagrant-landrush/landrush/issues/157))
- Added: Getting Landrush to work on Windows ([#16](https://github.com/vagrant-landrush/landrush/issues/16))

## [0.19.0] - 2016-03-10
- Added: Support for libvirt provider (#138)
- Added: support for CNAME records (#99)
- Breaking: Changing default TLD from `vagrant.dev` to `vagrant.test` (#118)

## [0.18.0] - 2015-01-24
- Added: support for `vagrant reload` (#101)

## [0.17.0] - 2015-01-18
- Added: cli `add` / `rm|del` subcommands (#96)
- Fixed: cli: default to showing help when no command is specified

## [0.16.0] - 2015-01-18
- Added: Support for IN::PTR records (#98)

[1.1.1]: https://github.com/phinze/landrush/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/phinze/landrush/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/phinze/landrush/compare/v0.19.0...v1.0.0
[0.19.0]: https://github.com/phinze/landrush/compare/v0.18.0...v0.19.0
[0.18.0]: https://github.com/phinze/landrush/compare/v0.17.0...v0.18.0
[0.17.0]: https://github.com/phinze/landrush/compare/v0.16.0...v0.17.0
[0.16.0]: https://github.com/phinze/landrush/compare/v0.15.4...v0.16.0
