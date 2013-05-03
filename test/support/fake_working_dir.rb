module FakeWorkingDirHooks
  def setup
    super
    VagrantRubydns.working_dir = '/tmp/vagrant_rubydns_test_working_dir'
  end

  def teardown
    super
    VagrantRubydns.working_dir.rmtree if VagrantRubydns.working_dir.directory?
  end
end

class MiniTest::Spec
  include FakeWorkingDirHooks
end

