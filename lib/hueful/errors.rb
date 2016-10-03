# frozen_string_literal: true

require 'hueful/version'

class Hueful::Bridge

  ##
  # A collection of errors from a hue bridge response.
  #
  # The HTTP response from a bridge can contain multiple error
  # messages; this class effectively wraps multiple {Error} objects
  # which come from a single response.
  class Errors < Exception

    # @return [Array<Hueful::Bridge::Error>]
    attr_reader :errors

    # @param errors [Array<Hueful::Bridge::Error>]
    def initialize errors
      @errors = errors
      message = errors.map(&:message).join(' ')
      super message
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

end
