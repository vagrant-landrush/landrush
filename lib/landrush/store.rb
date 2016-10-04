require 'pathname'
require 'json'

module Landrush
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
      write(current_config.merge(key => value))
    end

    def each(*args, &block)
      current_config.each(*args, &block)
    end

    def delete(key)
      write(current_config.reject { |k, v| k == key || v == key })
    end

    def has?(key, value = nil)
      if value.nil?
        current_config.key? key
      else
        current_config[key] == value
      end
    end

    def find(search)
      search = IPAddr.new(search).reverse if begin
                                                IPAddr.new(search)
                                              rescue
                                                nil
                                              end
      current_config.keys.detect do |key|
        key.casecmp(search) == 0   ||
          search =~ /#{key}$/i     ||
          key    =~ /^#{search}\./i
      end
    end

    def get(key)
      current_config[key]
    end

    def clear!
      write({})
    end

    protected

    def current_config
      if backing_file.exist?
        begin
          JSON.parse(File.read(backing_file))
        rescue JSON::ParserError
          {}
        end
      else
        {}
      end
    end

    def write(config)
      File.open(backing_file, 'w') do |f|
        f.write(JSON.pretty_generate(config))
      end
    end
  end
end
