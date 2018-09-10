module DeleteFakeWorkingDirHooks
  def teardown
    super
    FileUtils.rm_rf(@temp_dir)
  end
end

module MiniTest
  class Spec
    include DeleteFakeWorkingDirHooks
  end
end
