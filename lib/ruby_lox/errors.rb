# frozen_string_literal: true
# typed: strict

module RubyLox
  # Base error for all compile time errors.
  class LoxCompileError < RuntimeError
    extend T::Sig

    sig { params(token: Token, message: String).void }
    def initialize(token, message)
      super()
      @token = token
      @message = message
    end

    sig { returns(String) }
    def to_s
      "Compiler error on line #{@token.line}: #{@message}"
    end
  end

  # Base error for all runtime errors.
  class LoxRuntimeError < RuntimeError
    extend T::Sig

    sig { params(message: String).void }
    def initialize(message)
      super()
      @message = message
    end

    sig { returns(String) }
    def to_s
      "Runtime error: #{@message}"
    end
  end
end
