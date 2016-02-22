module CreateFakeWorkingDirHooks
  def setup
    super
    Landrush::Server.working_dir = Landrush::FakeConfig::TEST_LANDRUSH_DATA_DIR
  end
end

module MiniTest
  class Spec
    include CreateFakeWorkingDirHooks
  end
end
