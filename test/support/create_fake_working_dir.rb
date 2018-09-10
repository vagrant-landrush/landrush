module CreateFakeWorkingDirHooks
  def setup
    super
    @temp_dir = Dir.mktmpdir('vagrant_landrush_test_working_dir-')
    working_dir = File.join(@temp_dir, 'data', 'landrush')
    FileUtils.mkpath working_dir

    # Make sure that for all tests where we use Landrush::Server the working directory
    # is set to a temp directory.
    # this gets deleted in DeleteFakeWorkingDirHooks
    Landrush::Server.working_dir = working_dir
    Landrush::Server.gems_dir = gem_dir
  end
end

module MiniTest
  class Spec
    include CreateFakeWorkingDirHooks
  end
end
