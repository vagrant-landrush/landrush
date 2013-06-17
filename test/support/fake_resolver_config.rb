module FakeResolverConfigHooks
  def setup
    super
    @test_resolver_config = Pathname('/tmp/vagrant_landrush_test_resolver_config')
    Landrush::ResolverConfig.instance_variable_set(
      "@config_file",
      @test_resolver_config
    )
  end

  def teardown
    super
    if @test_resolver_config.exist?
      @test_resolver_config.delete
    end
  end
end

class MiniTest::Spec
  include FakeResolverConfigHooks
end
