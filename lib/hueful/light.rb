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
    @name = @client.rename_light self, new_name
  end

  attr_reader :on
  alias_method :on?, :on

  def turn_on
    @client.turn_on_light self
  end

  def turn_off
    @client.turn_off_light self
  end

  def toggle
    @on ? turn_off : turn_on
  end

  attr_reader :reachable
  alias_method :reachable?, :reachable


  # @!group State Management

  def update_state updates
    updates.each_pair do |key, value|
      instance_variable_set "@#{key}", value
    end
    self
  end

  def refresh
    json = @client.refresh_light self
    unpack_description json
    self
  end

  def inspect
    "#<Hueful::Light #{@name} #{state_string}>"
  end


  private

  def unpack_description json
    @name = json[:name]

    state = json[:state]
    @on = state[:on]
    @reachable = state[:reachable]
  end

  def state_string
    @on ? COLOUR.wrap('ON').green : COLOUR.wrap('OFF').red
  end

end
