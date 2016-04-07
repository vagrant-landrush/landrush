# Set test port so there's nothing colliding
Landrush::Server.port = 111_53

module SilenceOutput
  def silence
    orig_out = $stdout
    orig_err = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new
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

module Landrush
  class Server
    extend SilenceOutput
  end
end

module TestServerHooks
  def teardown
    super
    # Cleanup any stray server instances from tests
    if Landrush::Server.running?
      Landrush::Server.stop
    end
    Landrush::Store.reset
  end
end

module MiniTest
  class Spec
    include TestServerHooks
  end
end
