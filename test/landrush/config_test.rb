require_relative '../test_helper'

describe 'Landrush::Config' do
  it 'supports enabling via accessor style' do
    machine = fake_machine
    config = machine.config.landrush

    machine.config.landrush.enabled = true
    config.enabled?.must_equal true
    machine.config.landrush.enabled = false
    config.enabled?.must_equal false
  end

  it 'is backwards-compatible with the old method call style' do
    machine = fake_machine
    config = machine.config.landrush

    machine.config.landrush.enable
    config.enabled?.must_equal true
    machine.config.landrush.disable
    config.enabled?.must_equal false
  end

  it 'should validate host_interface_class' do
    machine = fake_machine
    config = machine.config.landrush

    validation_success = []
    validation_error = [Landrush::Config::INTERFACE_CLASS_INVALID, { fields: 'host_interface_class' }]

    Landrush::Config::INTERFACE_CLASSES.each do |sym|
      machine.config.landrush.host_interface_class = sym
      config.validate(machine).must_equal('landrush' => validation_success)

      machine.config.landrush.host_interface_class = sym.to_s
      config.validate(machine).must_equal('landrush' => validation_success)
    end

    [:invalid_symbol, 'invalid_string', 4].each do |v|
      machine.config.landrush.host_interface_class = v
      config.validate(machine).must_equal('landrush' => validation_error)
    end
  end
end
