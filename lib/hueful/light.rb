require 'hueful/version'

require 'rainbow'


class Hueful::Light

  COLOUR = Rainbow.new

  attr_reader :index

  def initialize json, client
    @index = json.first
    @client = client
    unpack_description json.last
  end


  # @!group API

  attr_reader :name

  def name= new_name
    @name = @client.bridge.light_rename @client.token, @index, new_name
  end

  attr_reader :on
  alias_method :on?, :on
  # @!group State Management

  def refresh
    json = @client.bridge.light @client.token, @index
    unpack_description json
    self
  end

  def inspect
    "#<Hueful::Light #{@name} #{state_string}>"
  end

  def method_missing meth, *args
    if (value = @json[meth])
      value
    else
      super
    end
  end


  private

  def unpack_description json
    @name = json[:name]

    state = json[:state]
    @on = state[:on]
    @reachable = state[:reachable]
  end

  def state_string
    on? ? COLOUR.wrap('ON').green : COLOUR.wrap('OFF').red
  end

end
