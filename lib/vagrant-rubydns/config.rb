module VagrantRubydns
  class Config
    CONFIG_FILE = Pathname('.vagrant_dns.json')

    def self.set(key, value)
      write(current_config.merge(key => value))
    end

    def self.delete(key)
      write(current_config.reject { |k, _| k == key })
    end

    def self.get(key)
      current_config[key]
    end

    def self.clear!
      write({})
    end

    protected

    def self.current_config
      if CONFIG_FILE.exist?
        JSON.parse(File.read(CONFIG_FILE))
      else
        {}
      end
    end

    def self.write(config)
      File.open(CONFIG_FILE, "w") do |f|
        f.write(JSON.pretty_generate(config))
      end
    end
  end
end
