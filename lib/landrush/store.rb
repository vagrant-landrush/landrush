module Landrush
  class Store
    def self.hosts
      @hosts ||= new(Landrush.working_dir.join('hosts.json'))
    end

    attr_accessor :backing_file

    def initialize(backing_file)
      @backing_file = Pathname(backing_file)
    end

    def set(key, value, type = 'a')
      config = current_config
      config[type] = (config[type] || {}).merge(key => value)
      write(config)
    end

    def each(*args, &block)
      current_config.each(*args, &block)
    end

    def delete(key, type = 'a')
      config = current_config
      config[type] = (config[type] || {}).reject { |k, v| k == key || v == key }
      write(config)
    end

    def find(search, type = 'a')
      search = (IPAddr.new(search).reverse) if (IPAddr.new(search) rescue nil)
      (current_config[type] || {}).keys.detect do |key|
        key.casecmp(search) == 0   ||
          search =~ /#{key}$/i     ||
          key    =~ /^#{search}\./i
      end
    end

    def get(key, type = 'a')
      (current_config[type] || {})[key]
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
