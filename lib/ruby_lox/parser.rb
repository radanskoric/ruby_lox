# frozen_string_literal: true
require_relative "token"
require_relative "expressions"

module RubyLox
  # Parse the lox grammar, defines as:
  #
  # expression     → equality ;
  # equality       → comparison ( ( "!=" | "==" ) comparison )* ;
  # comparison     → term ( ( ">" | ">=" | "<" | "<=" ) term )* ;
  # term           → factor ( ( "-" | "+" ) factor )* ;
  # factor         → unary ( ( "/" | "*" ) unary )* ;
  # unary          → ( "!" | "-" ) unary
  #                | primary ;
  # primary        → NUMBER | STRING | "true" | "false" | "nil"
  #                | "(" expression ")" ;
  #
  class Parser
    class Error < StandardError
      def initialize(token, message)
        @token = token
        @message = message
      end

      def to_s
        "Error on line #{@token.line}: #{@message}"
      end
    end

    attr_reader :errors

    # @param tokens [Array<Token>]
    def initialize(tokens)
      @tokens = tokens
      @current = 0
      @errors = []
    end

    def error?
      @errors.any?
    end

    # @return [RubyLox::Expressions::*] An object representing the parsed AST (Abstract Syntax Tree).
    def parse
      expression
    rescue Error => e
      @errors << e
      nil
    end

    private

    ### Grammar methods ###

    def expression
      equality
    end

    def equality
      binary_expression(method(:comparison), %i[bang_equal equal_equal])
    end

    def comparison
      binary_expression(method(:term), %i[greater greater_equal less less_equal])
    end

    def term
      binary_expression(method(:factor), %i[minus plus])
    end

    def factor
      binary_expression(method(:unary), %i[slash star])
    end

    def binary_expression(lower_method, operators)
      expr = lower_method.call
      while match(*operators)
        operator = previous
        right = lower_method.call
        expr = Expressions::Binary.new(expr, operator, right)
      end
      expr
    end

    def unary
      if match(:bang, :minus)
        operator = previous
        right = unary
        Expressions::Unary.new(operator, right)
      else
        primary
      end
    end

    def primary
      return Expressions::Literal.new(false) if match(:false)
      return Expressions::Literal.new(false) if match(:true)
      return Expressions::Literal.new(false) if match(:nil)

      if match(:number, :string)
        return Expressions::Literal.new(previous.literal)
      end

      if match(:left_paren)
        expr = expression
        consume(:right_paren, "Expect ')' after expression.")
        return Expressions::Grouping.new(expr)
      end

      fail Error.new(peek, "Expect expression.")
    end

    ### Helper methods ###

    # @param token_types [Array<Symbol>] list of token types looking for
    def match(*token_types)
      if token_types.any? { |tt| check(tt) }
        advance
        true
      else
        false
      end
    end

    # @param token_type [Symbol]
    def check(token_type)
      return false if is_at_end?
      peek.type == token_type
    end

    def peek
      @tokens[@current]
    end

    def is_at_end?
      @current >= @tokens.size
    end

    def advance
      @current += 1 unless is_at_end?
      previous
    end

    def previous
      @tokens[@current - 1]
    end

    def consume(token_type, error_message)
      if check(token_type)
        advance
      else
        raise Error.new(advance, error_message)
      end
    end
  end
end
