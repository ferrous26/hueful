require 'hueful/version'
require 'hueful/client'
require 'hueful/light'

require 'json'
require 'nokogiri'


class Hueful::Bridge

  class << self

    # @return [Array<Hueful::Bridge>]
    def discover method: :nupnp
      case method
      when :cached      then discover_cached
      when :ssdp, :upnp then discover_ssdp
      when :nupnp       then discover_nupnp
      else
        raise ArgumentError, "`#{method}' is not a valid discovery method"
      end
    end

    def discover_ssdp timeout: 5
      require 'ssdp'

      consumer = SSDP::Consumer.new service: 'ssdp:all',
                                    synchronous: true,
                                    timeout: timeout

      bridges = {}
      consumer.search.each { |service|
        if (id = service[:params]['hue-bridgeid'])
          bridges[id] = service[:address]
        end
      }

      bridges.values.map { |ip| new ip }

    rescue LoadError
      raise 'You need to install the ssdp gem first'
    end

    def discover_nupnp
      resp = HTTP.get('https://www.meethue.com/api/nupnp')

      case resp.status.code
      when 200
        Hueful.parse_json(resp.body).map { |service|
          new service[:internalipaddress]
        }
      else
        raise RuntimeError, resp.status.inspect
      end
    end

    def discover_cached path = Hueful.default_config_path
      config  = Hueful.parse_json File.read path
      ip_addr = config[:last_ip_address]
      [new(ip_addr)]
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
