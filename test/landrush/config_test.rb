require 'test_helper'

describe 'Landrush::Config' do
  it "supports enabling via accessor style" do
    machine = fake_machine
    config = machine.config.landrush

    machine.config.landrush.enabled = true
    config.enabled?.must_equal true
    machine.config.landrush.enabled = false
    config.enabled?.must_equal false
  end

  it "is backwards-compatible with the old method call style" do
    machine = fake_machine
    config = machine.config.landrush

    machine.config.landrush.enable
    config.enabled?.must_equal true
    machine.config.landrush.disable
    config.enabled?.must_equal false
  end
end
