# frozen_string_literal: true

module RubyLox
  class Token
    TYPES = %i[
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
    ].freeze

    attr_reader :type, :line, :literal, :lexeme

    # @param type [Symbol] Type of token
    # @param lexeme [String] The actual snippet of course matching the token
    # @param literal [Symbol, String, Number] the value of a literal for literal tokens.
    # @param line [Integer] Source line on which the token appears
    def initialize(type, lexeme, literal, line)
      raise ArgumentError, "Unknown token type: #{type}" unless TYPES.include?(type)

      @type = type
      @lexeme = lexeme
      @literal = literal
      @line = line
    end

    def to_s
      "#{@type} #{@lexeme} #{@literal}"
    end

    def ==(other)
      self.type == other.type && self.literal == other.literal
    end
    alias eql? ==

    def hash
      [type, literal].hash
    end
  end
end
