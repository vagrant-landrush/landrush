module ClearDependentVms
  def setup
    super
    Landrush::DependentVMs.clear!
  end
end

module MiniTest
  class Spec
    include ClearDependentVms
  end
end
