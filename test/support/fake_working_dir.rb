module FakeWorkingDirHooks
  def setup
    super
    tempdir = Dir.mktmpdir('vagrant_landrush_test_working_dir-')
    Landrush::Server.working_dir = tempdir
  end

  def teardown
    super
    Landrush::Server.working_dir.rmtree if Landrush::Server.working_dir.directory?
  end
end

module MiniTest
  class Spec
    include FakeWorkingDirHooks
  end
end
