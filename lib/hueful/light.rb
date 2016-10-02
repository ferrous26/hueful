require 'hueful/version'

class Hueful::Light

  attr_reader :index

  def initialize json, client
    @index = json.first
    @json = json.last
    @client = client
  end

  def method_missing meth, *args
    if (value = @json[meth])
      value
    else
      super
    end
  end

end
