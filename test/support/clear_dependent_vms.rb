module ClearDependentVms
  def setup
    super
    Landrush::DependentVMs.clear!
  end
end

class MiniTest::Spec
  include ClearDependentVms
end
