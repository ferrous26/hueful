require 'hueful/version'
require 'hueful/bridge'
require 'hueful/light'


class Hueful::Client

  class << self
    def load_cached config_path = Hueful.default_config_path
      config = Hueful.load_config config_path
      bridge = Hueful::Bridge.new config[:last_ip_address]
      new bridge, config[:token]
    end
  end

  attr_reader :bridge
  attr_reader :token

  def initialize bridge, token
    @bridge = bridge
    @token = token
  end


  # @!group Persistence

  def cache_token config_path = Hueful.default_config_path
    Hueful.cache_config config_path,
                        last_ip_address: @bridge.ip_address,
                        token: @token
  end


  # @!group API

  def lights
    @bridge.lights(@token).map { |json|
      Hueful::Light.new json, self
    }
  end

end
