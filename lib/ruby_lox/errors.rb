# frozen_string_literal: true

module RubyLox
  # Base error for all runtime errors.
  class LoxRuntimeError < RuntimeError
    def initialize(message)
      @message = message
    end

    def to_s
      "Runtime error: #{@message}"
    end
  end
end
