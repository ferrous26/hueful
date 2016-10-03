require 'hueful/version'

class Hueful::Bridge

  ##
  # Methods for discovering hue bridges.
  #
  # For a responsive app, you will want to try all methods in parallel.
  module Discovery
    module_function

    ##
    # @note You will need the `ssdp` gem for this discovery method
    #
    # Discover bridges on the local network using the universal plug-n-play
    # simple service discovery protocol (uPnP SSDP).
    #
    # This discovery method is recommended by Philips as the first method
    # of discovery to try, though it is implemented here in a synchronous
    # manner with a long default timeout.
    #
    # @param timeout [Integer] timeout in seconds
    # @return [Array<String>] list of IP addresses
    def ssdp timeout: 5
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

      bridges.values

    rescue LoadError
      raise 'You need to install the ssdp gem first'
    end

    ##
    # Discover bridges on the local network by contacting Philips and asking
    # them which bridges have registered themselves from the public IP address.
    #
    # In practice, this method is much faster than {.ssdp}, but it will not
    # work in complicated network setups or if local network cannot reach the
    # internet.
    #
    # @return [Array<String>] list of IP addresses
    def nupnp
      resp = HTTP.get('https://www.meethue.com/api/nupnp')

      case resp.status.code
      when 200
        Hueful.parse_json(resp.body).map { |service|
          service[:internalipaddress]
        }
      else
        raise RuntimeError, resp.status.inspect
      end
    end

    ##
    # Load the address of a bridge that was previously cached.
    #
    # For an environment that does not change often (i.e. most homes), this
    # method is by far the best way to "discover" a bridge. In order to use
    # this method you must have previously cached a bridge configuration
    # using {Hueful::Bridge#cache_config}.
    #
    # @return [Array<String>] list of IP addresses
    def cached path = Hueful.default_config_path
      config  = Hueful.parse_json File.read path
      ip_addr = config[:last_ip_address]
      [ip_addr]
    end

  end

end
