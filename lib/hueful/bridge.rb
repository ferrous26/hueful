require 'hueful/version'
require 'hueful/client'
require 'hueful/discovery'
require 'hueful/light'

require 'json'
require 'nokogiri'


##
# Bridge is a proxy for a Philips hue bridge.
#
# This class exposes (most of) the API provided by the hue bridge in an
# object oriented manner. Exceptions will be raised in the case of errors.
#
# Bridges are instantiated following the API guidelines, either by one of
# the discovery methods or by loading cached configuration from a file.
class Hueful::Bridge

  # @return [Array<Hueful::Bridge>]
  def self.discover method: :nupnp
    ip_addrs = case method
               when :cached      then Discovery.cached
               when :ssdp, :upnp then Discovery.ssdp
               when :nupnp       then Discovery.nupnp
               else
                 raise ArgumentError, "`#{method}' is not a discovery method"
               end

    ip_addrs.map { |ip| new(ip) }
  end



    end

  end

  class Error < Exception

    attr_reader :type
    attr_reader :address

    def initialize error_obj
      @type, @address, message =
        error_obj.values_at 'type', 'address', 'description'
      super message
    end

  end

  attr_reader :ip_address
  attr_reader :serial_number
  attr_reader :friendly_name

  def initialize ip_address
    @ip_address = ip_address
    @connection = HTTP.persistent "http://#{ip_address}"
    unpack_description
  end

  def cache_config config_path = Hueful.default_config_path
    Hueful.cache_config last_ip_address: @ip_address
  end


  # @!group API

  # @return [String]
  def new_auth_token app_name
    body = { devicetype: app_name }
    resp = @connection.post('/api', body: body.to_json)

    handle_http_error resp

    result = Hueful.parse_json(resp.body).first
    if (token = result[:success])
      token[:username]

    elsif (error = result[:error])
      raise Error.new(error)

    end
  end

  # @return [Hueful::Client]
  def new_client app_name
    client new_auth_token app_name
  end

  # @return [Hueful::Client]
  def client token
    Hueful::Client.new self, token
  end

  # @return [Array<Hash>]
  def lights token
    resp = @connection.get "/api/#{token}/lights"
    handle_http_error resp
    Hueful.parse_json resp.body
  end

  # @return [Hash]
  def light token, index
    resp = @connection.get "/api/#{token}/lights/#{index}"
    handle_http_error resp
    Hueful.parse_json(resp.body)
  end

  # @return [String]
  def light_rename token, index, new_name
    body = { name: new_name }
    resp = @connection.put "/api/#{token}/lights/#{index}", body: body.to_json
    parse_json_response(resp).values.first
  end

  # @return [Hash]
  def light_update token, index, updates = {}
    resp = @connection.put "/api/#{token}/lights/#{index}/state",
                           body: updates.to_json

    results = parse_json_response(resp).map { |key, value|
      key = key.to_s.split('/').last.to_sym
      [key, value]
    }

    Hash[results]
  end


  # @!group Misc.

  def inspect
    "#<Hue::Bridge #{@friendly_name}>"
  end


  private

  def handle_http_error response
    return if response.status.code == 200
    raise RuntimeError, response.status.inspect
  end

  def parse_json_response response
    handle_http_error response

    results = Hueful.parse_json(response.body).map do |r|
      if (attr = r[:success])
        attr.first
      else
        raise Error.new(r)
      end
    end

    Hash[results]
  end

  def unpack_description
    # BUG: using the persistent @connection here seems to cause problems with
    # my bridge; using the @connection here and then trying a main API call
    # within a few seconds causes the bridge to return a malformed response;
    # but using a separate connection here seems to avoid that issue
    resp = HTTP.get "http://#{@ip_address}/description.xml"
    handle_http_error resp

    doc = Nokogiri::XML(resp.body.to_s)
    device_info = doc.xpath('/xmlns:root/xmlns:device')

    @serial_number = device_info.xpath('./xmlns:serialNumber').first.inner_text
    @friendly_name = device_info.xpath('./xmlns:friendlyName').first.inner_text
  end

end
