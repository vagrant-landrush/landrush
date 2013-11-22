module FakeResolverConfigHooks
  def setup
    super
    @test_resolver_config_dir = Pathname('/tmp/landrush_fake_resolver')
    Landrush::ResolverConfig.instance_variable_set(
      "@config_dir",
      @test_resolver_config_dir
    )
  end

  def teardown
    super
    if @test_resolver_config_dir.exist?
      @test_resolver_config_dir.rmtree
    end
  end
end

class MiniTest::Spec
  include FakeResolverConfigHooks
end
