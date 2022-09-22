# frozen_string_literal: true
require_relative "token"
require_relative "expressions"
require_relative "statements"

module RubyLox
  # Parse the lox grammar, defines as:
  #
  # program        → declaration* EOF ;
  # declaration    → varDecl | statement;
  # varDecl        → "var" IDENTIFIER ("=" expression)? ";" ;
  # statement      → exprStmt | ifStmt | printStmt | block ;
  # exprStmt       → expression ";" ;
  # printStmt      → "print" expression ";" ;
  # block          → "{" declaration* "}" ;
  # expression     → assignment ;
  # ifStmt         → "if" "(" expression ")" statement
  #                  ( "else" statement )? ;
  # assignment     → IDENTIFIER "=" assignment
  #                | equality ;
  # equality       → comparison ( ( "!=" | "==" ) comparison )* ;
  # comparison     → term ( ( ">" | ">=" | "<" | "<=" ) term )* ;
  # term           → factor ( ( "-" | "+" ) factor )* ;
  # factor         → unary ( ( "/" | "*" ) unary )* ;
  # unary          → ( "!" | "-" ) unary
  #                | primary ;
  # primary        → NUMBER | STRING | "true" | "false" | "nil"
  #                | "(" expression ")" | IDENTIFIER ;
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

    STATEMENT_START_TOKENS = %i[class for fun if print return var while].freeze

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
      statements = []
      while !(is_at_end? || match(:eof))
        statements << declaration
      end

      statements.compact
    rescue Error => e
      @errors << e
      nil
    end

    private

    ### Grammar methods ###

    def declaration
      begin
        return var_declaration if match(:var)
        statement
      rescue Error => e
        @errors << e
        synchronize
        nil
      end
    end

    def var_declaration
      name = consume(:identifier, "Expect variable name.")

      initializer = nil
      if match(:equal)
        initializer = expression
      end

      consume(:semicolon, "Expect ';' after variable declaration.")
      Statements::VarDecl.new(name, initializer)
    end

    def statement
      return ifStatement if match(:if)
      return printStatement if match(:print)
      return block if match(:left_brace)

      expressionStatement
    end

    def ifStatement
      consume(:left_paren, "Expect '(' after if.")
      condition = expression
      consume(:right_paren, "Expect ')' after if condition.")

      thenBranch = statement
      elseBranch = match(:else) ? statement : nil

      Statements::If.new(condition, thenBranch, elseBranch)
    end

    def printStatement
      expr = expression
      consume(:semicolon, "Expect ';' after expression.")
      Statements::Print.new(expr)
    end

    def block
      statements = []

      while !check(:right_brace) && !is_at_end?
        statements << declaration
      end

      consume(:right_brace, "Expect '}' after block.")

      Statements::Block.new(statements)
    end

    def expressionStatement
      expr = expression
      consume(:semicolon, "Expect ';' after expression.")
      Statements::Expression.new(expr)
    end

    def expression
      assignment
    end

    def assignment
      expr = equality

      if match(:equal)
        equals = previous
        value = assignment

        if expr.is_a?(Expressions::Variable)
          return Expressions::Assign.new(expr.name, value)
        end

        fail Error.new(equals, "Invalid assignment target.")
      end

      expr
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
      return Expressions::Literal.new(true) if match(:true)
      return Expressions::Literal.new(nil) if match(:nil)

      if match(:number, :string)
        return Expressions::Literal.new(previous.literal)
      end

      if match(:identifier)
        return Expressions::Variable.new(previous.lexeme)
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
      if check(*token_types)
        advance
        true
      else
        false
      end
    end

    # @param token_type [Symbol]
    def check(*token_types)
      return false if is_at_end?
      token_types.include?(peek.type)
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

    def synchronize
      advance
      while !is_at_end?
        return if previous.type == :semicolon
        return if STATEMENT_START_TOKENS.include?(peek.type)

        advance
      end
    end
  end
end
