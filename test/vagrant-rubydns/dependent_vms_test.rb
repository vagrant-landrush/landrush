require 'test_helper'

module VagrantRubydns
  describe DependentVMs do
    describe "any?" do
      it "reports false when nothing has happened" do
        DependentVMs.any?.must_equal false
      end

      it "reports true once a machine has been added" do
        env = fake_environment_with_machine('recordme.example.dev', '1.2.3.4')
        DependentVMs.add(env[:machine])
        DependentVMs.any?.must_equal true
      end

      it "reports false if a machine has been added then removed" do
        env = fake_environment_with_machine('recordme.example.dev', '1.2.3.4')
        DependentVMs.add(env[:machine])
        DependentVMs.remove(env[:machine])
        DependentVMs.any?.must_equal false
      end

      it "reports true if not all machines have been removed" do
        first_env = fake_environment_with_machine('recordme.example.dev', '1.2.3.4')
        second_env = fake_environment_with_machine('alsome.example.dev', '2.3.4.5')
        DependentVMs.add(first_env[:machine])
        DependentVMs.add(second_env[:machine])
        DependentVMs.remove(first_env[:machine])
        DependentVMs.any?.must_equal true
      end
    end
  end
end
