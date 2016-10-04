# Set test port so there's nothing colliding
Landrush::Server.port = 111_53

module SilenceOutput
  def self.silence
    orig_out = $stdout
    orig_err = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new
    yield
  ensure
    $stdout = orig_out
    $stderr = orig_err
  end

  def self.included(base)
    orig_stop_method = base.method(:stop)
    base.define_singleton_method :stop do
      SilenceOutput.silence { orig_stop_method.call }
    end
  end
end

module Landrush
  class Server
    include SilenceOutput
  end
end

module TestServerHooks
  def teardown
    super
    # Cleanup any stray server instances from tests
    Landrush::Server.stop if Landrush::Server.running?
    Landrush::Store.reset
  end
end

module MiniTest
  class Spec
    include TestServerHooks
  end
end
