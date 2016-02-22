module DeleteFakeWorkingDirHooks
  def teardown
    super
    FileUtils.rmtree Landrush::FakeConfig::TEST_LANDRUSH_DATA_DIR
  end
end

module MiniTest
  class Spec
    include DeleteFakeWorkingDirHooks
  end
end
