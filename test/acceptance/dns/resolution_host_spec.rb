shared_examples 'provider/resolution_host' do |provider, options|
  unless options[:box]
    fail ArgumentError, "box option must be specified for provider: #{provider}"
  end

  include_context 'acceptance'

  before do
    environment.skeleton('landrush_basic')
    assert_execute('sed', '-i', '', '-e', "s|{{box}}|#{options[:box]}|g", 'Vagrantfile')
    assert_execute('vagrant', 'up', "--provider=#{provider}")
  end

  after do
    assert_execute('vagrant', 'destroy', '--force')
  end

  it 'sets up DNS resolution on the host' do
    result = execute('dig', '+short', '@localhost', '-p', '10053', 'my-host', 'A')
    expect(result).to exit_with(0)
    expect(result.stdout).to match(/^10.10.10.123$/)
  end
end
