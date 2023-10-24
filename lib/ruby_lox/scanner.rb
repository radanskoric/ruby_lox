# frozen_string_literal: true

require_relative "token"

module RubyLox
  class Scanner
    DIGITS = ("0".."9").freeze
    ALPHA = /[a-zA-Z_]/.freeze

    RESERVED_WORDS = %w[
      and class else false fun for if nil or
      print return super this true var while
    ].freeze

    class LexicalError
      def initialize(character, line)
        @character = character
        @line = line
      end

      def to_s
        "Unexpected character \"#{@character}\" on line #{@line}"
      end
    end

    class UnclosedString < LexicalError
      def to_s
        "Expected string closing quote \" but found none on line #{@line}"
      end
    end

    attr_reader :errors

    # @param source [String]
    def initialize(source)
      @source = source

      @start = 0
      @current = 0
      @line = 1
      @errors = []
    end

    def error?
      @errors.any?
    end

    # @return [Array<RubyLox::Token>]
    def scan_tokens
      return @tokens if @tokens

      @tokens = []

      while !end?
        @start = @current
        scan_token
      end

      @tokens << Token.new(:eof, "", nil, @line)
      @tokens
    end

    private

    def end?
      @current >= @source.size
    end

    def scan_token
      c = advance
      case c
      when "(" then add_token(:left_paren)
      when ")" then add_token(:right_paren)
      when "{" then add_token(:left_brace)
      when "}" then add_token(:right_brace)
      when "," then add_token(:comma)
      when "." then add_token(:dot)
      when "-" then add_token(:minus)
      when "+" then add_token(:plus)
      when ";" then add_token(:semicolon)
      when "*" then add_token(:star)
      when "!" then add_token(match("=") ? :bang_equal : :bang)
      when "=" then add_token(match("=") ? :equal_equal : :equal)
      when "<" then add_token(match("=") ? :less_equal : :less)
      when ">" then add_token(match("=") ? :greater_equal : :greater)
      when "/" then
        if match("/")
          advance while peek != "\n" && !end?
        else
          add_token(:slash)
        end
      when '"' then scan_string
      when DIGITS then scan_number
      when ALPHA then scan_identifier
      when "\n" then
        @line += 1
        nil
      when /\s/ then nil
      else
        @errors << LexicalError.new(c, @line)
        nil
      end
    end

    def advance
      next_char = @source[@current]
      @current += 1
      next_char
    end

    def match(c)
      return false if end?

      peek == c ? advance : false
    end

    def peek
      @source[@current]
    end

    def peek_next
      @source[@current + 1]
    end

    def add_token(type, literal = nil)
      @tokens << Token.new(type, @source[@start..@current - 1], literal, @line)
    end

    def scan_string
      while peek != '"' && !end?
        @line += 1 if peek == "\n"
        advance
      end

      if match('"')
        add_token(:string, @source[@start + 1..@current - 2])
      else
        @errors << UnclosedString.new(peek, @line)
      end
    end

    def scan_number
      advance while DIGITS.include?(peek)

      if peek == "." && DIGITS.include?(peek_next)
        advance
        advance while DIGITS.include?(peek)
      end

      add_token(:number, @source[@start..@current - 1].to_f)
    end

    def scan_identifier
      advance while isAlphaNumeric(peek)
      value = @source[@start..@current - 1]
      if RESERVED_WORDS.include?(value)
        add_token(value.to_sym)
      else
        add_token(:identifier, value)
      end
    end

    def isAlphaNumeric(c)
      ALPHA.match?(c) || DIGITS.include?(c)
    end
  end
end
