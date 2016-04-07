require 'tmpdir'

module FakeResolverConfigHooks
  def setup
    super
    tempdir = Dir.mktmpdir('landrush_fake_resolver')
    @test_resolver_config_dir = Pathname(tempdir)
    Landrush::ResolverConfig.config_dir = @test_resolver_config_dir
    Landrush::ResolverConfig.sudo       = ''
  end

  def teardown
    super
    Landrush::ResolverConfig.sudo = 'sudo'
    if @test_resolver_config_dir.exist?
      @test_resolver_config_dir.rmtree
    end
  end
end

module MiniTest
  class Spec
    include FakeResolverConfigHooks
  end
end
