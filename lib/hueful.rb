require 'hueful/version'
require 'hueful/bridge'
require 'hueful/client'

require 'http'

module Hueful

  class << self

    def default_config_path
      File.expand_path '~/.hueful'
    end

    def load_config path = default_config_path
      return {} unless File.exist? path
      parse_json File.read path
    end

    def cache_config path = default_config_path, config = {}
      updated_config = load_config(path).merge(config)
      File.open(path, 'w') do |fd|
        fd.write updated_config.to_json
      end
    end

    def parse_json json
      JSON::Parser.new(json, symbolize_names: true).parse
    end

    def discover
      Hueful::Bridge.discover
    end

    def load_cached_client path = default_config_path
      Hueful::Client.load_cached path
    end

  end

end
