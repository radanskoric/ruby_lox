# frozen_string_literal: true
# typed: true

module RubyLox
  # Base error for all compile time errors.
  class LoxCompileError < RuntimeError
    def initialize(token, message)
      super()
      @token = token
      @message = message
    end

    def to_s
      "Compiler error on line #{@token.line}: #{@message}"
    end
  end

  # Base error for all runtime errors.
  class LoxRuntimeError < RuntimeError
    def initialize(message)
      super()
      @message = message
    end

    def to_s
      "Runtime error: #{@message}"
    end
  end
end
