# Set test port so there's nothing colliding
Landrush::Server.port = 11153

module SilenceOutput
  def silence
    orig_out, orig_err = $stdout, $stderr
    $stdout, $stderr   = StringIO.new, StringIO.new

    yield
  ensure
    $stdout = orig_out
    $stderr = orig_err
  end

  def start
    silence { super }
  end

  def stop
    silence { super }
  end
end

class Landrush::Server
  extend SilenceOutput
end

module TestServerHooks
  def teardown
    super
    # Cleanup any stray server instances from tests
    if Landrush::Server.running?
      Landrush::Server.stop
    end
  end
end

class MiniTest::Spec
  include TestServerHooks
end
