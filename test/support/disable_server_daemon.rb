class VagrantRubydns::Server < RExec::Daemon::Base
  def self.start
    @start_count += 1
  end

  def self.stop
    @stop_count += 1
  end

  def self.running?
    @start_count > 0
  end

  def self.clear!
    @start_count = 0
    @stop_count = 0
  end

  def self.start_count
    @start_count
  end

  def self.stop_count
    @stop_count
  end
end

module FakeServerHooks
  def setup
    super
    VagrantRubydns::Server.clear!
  end
end

class MiniTest::Spec
  include FakeServerHooks
end
