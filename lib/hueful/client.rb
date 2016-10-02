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


  # @!group Light API

  def lights
    @bridge.lights(@token).map { |json| Hueful::Light.new(json, self) }
  end

  def refresh_light light
    @bridge.light @token, light.index
  end

  def rename_light light, new_name
    @bridge.light_rename @token, light.index, new_name
  end

  def update_light light, updates = {}
    result = @bridge.light_update @token, light.index, updates
    light.update_state result
  end

  def turn_on_light light
    update_light light, on: true
  end

  def turn_off_light light
    update_light light, on: false
  end

end
