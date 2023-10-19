# frozen_string_literal: true
# typed: strict

require 'sorbet-runtime'

module RubyLox
  class Token
    extend T::Sig
    TYPES = T.let(%i[
      left_paren right_paren left_brace right_brace
      comma dot minus plus semicolon slash star

      bang bang_equal
      equal equal_equal
      greater greater_equal
      less less_equal

      identifier string number

      and class else false fun for if nil or
      print return super this true var while

      eof
    ].freeze, T::Array[Symbol])

    sig { returns(Symbol) }
    attr_reader :type
    sig { returns(Integer) }
    attr_reader :line
    sig { returns(T.nilable(T.any(Symbol, String, Numeric))) }
    attr_reader :literal
    sig { returns(String) }
    attr_reader :lexeme

    # @param type [Symbol] Type of token
    # @param lexeme [String] The actual snippet of course matching the token
    # @param literal [Symbol, String, Numeric] the value of a literal for literal tokens.
    # @param line [Integer] Source line on which the token appears
    sig { params(type: Symbol, lexeme: String, literal: T.nilable(T.any(Symbol, String, Numeric)), line: Integer).void }
    def initialize(type, lexeme, literal, line)
      raise ArgumentError, "Unknown token type: #{type}" unless TYPES.include?(type)

      @type = type
      @lexeme = lexeme
      @literal = literal
      @line = line
    end

    sig { returns(String) }
    def to_s
      "#{@type} #{@lexeme} #{@literal}"
    end

    # We want to be able to compare two ASTs so we need this looser method.
    # But for hash lookup we need to distinguish between tokens with the same
    # source but in different location. Therefore we will leave `eql?` and `hash`
    # unmodified.
    sig { params(other: T.untyped).returns(T::Boolean) }
    def ==(other)
      self.type == other.type && self.literal == other.literal
    end
  end
end
