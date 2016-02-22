module DeleteFakeWorkingDirHooks
  def teardown
    super
    Landrush::Server.working_dir.rmtree if Landrush::Server.working_dir.directory?
  end
end

module MiniTest
  class Spec
    include DeleteFakeWorkingDirHooks
  end
end
