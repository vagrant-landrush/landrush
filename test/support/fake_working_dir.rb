module FakeWorkingDirHooks
  def setup
    super
    Landrush.working_dir = '/tmp/vagrant_landrush_test_working_dir'
  end

  def teardown
    super
    Landrush.working_dir.rmtree if Landrush.working_dir.directory?
  end
end

class MiniTest::Spec
  include FakeWorkingDirHooks
end

