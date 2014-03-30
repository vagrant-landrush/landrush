module Landrush
  class Store
    def self.hosts
      @hosts ||= new(Landrush.working_dir.join('hosts.json'))
    end

    def self.config
      @config ||= new(Landrush.working_dir.join('config.json'))
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
      write(current_config.reject { |k, _| k == key })
    end

    def find(search)
      current_config.keys.detect do |key|
        key.casecmp(search) == 0   ||
          search =~ /#{key}$/i     ||
          key    =~ /^#{search}\./i
      end
    end

    def get(key)
      value = current_config[key]
      redirect = nil
      if value.is_a? String
        redirect = find(value)
      end
      if value
        if redirect
          get(redirect)
        else
          value
        end
      end
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
      File.open(backing_file, "w") do |f|
        f.write(JSON.pretty_generate(config))
      end
    end
  end
end
