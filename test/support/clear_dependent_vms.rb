module ClearDependentVms
  def setup
    super
    VagrantRubydns::DependentVMs.clear!
  end
end

class MiniTest::Spec
  include ClearDependentVms
end
