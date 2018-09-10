require 'pathname'
require 'json'
require 'filelock'

module Landrush
  class ConfigLockError < StandardError
  end

  class Store
    def self.hosts
      @hosts ||= new(Server.working_dir.join('hosts.json'))
    end

    def self.config
      @config ||= new(Server.working_dir.join('config.json'))
    end

    def self.reset
      @config = nil
      @hosts = nil
    end

    attr_accessor :backing_file

    def initialize(backing_file)
      @backing_file = Pathname(backing_file)
    end

    def set(key, value)
      with_file_lock do |file|
        config = current_config(file).merge(key => value)
        write(config, file)
      end
    end

    def each(*args, &block)
      with_file_lock do |file|
        current_config(file).each(*args, &block)
      end
    end

    def delete(key)
      with_file_lock do |file|
        write(current_config(file).reject { |k, v| k == key || v == key }, file)
      end
    end

    def has?(key, value = nil)
      with_file_lock do |file|
        if value.nil?
          current_config(file).key? key
        else
          current_config(file)[key] == value
        end
      end
    end

    def find(search)
      with_file_lock do |file|
        search = IPAddr.new(search).reverse if begin
                                                 IPAddr.new(search)
                                               rescue StandardError
                                                 nil
                                               end
        current_config(file).keys.detect do |key|
          key.casecmp(search) == 0   ||
            search =~ /#{key}$/i     ||
            key    =~ /^#{search}\./i
        end
      end
    end

    def get(key)
      with_file_lock do |file|
        current_config(file)[key]
      end
    end

    def clear!
      with_file_lock do |file|
        write({}, file)
      end
    end

    protected

    def with_file_lock
      Filelock @backing_file.to_s, wait: 3 do |file|
        yield file
      end
    rescue Filelock::WaitTimeout
      raise ConfigLockError, 'Unable to lock Landrush config'
    end

    def current_config(file)
      if backing_file.exist?
        begin
          file.rewind
          JSON.parse(file.read)
        rescue JSON::ParserError
          {}
        end
      else
        {}
      end
    end

    def write(config, file)
      file.rewind
      file.truncate(0)
      file.write(JSON.pretty_generate(config))
      file.flush
    end
  end
end
