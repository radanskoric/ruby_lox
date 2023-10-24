# frozen_string_literal: true

require_relative "token"
require_relative "expressions"
require_relative "statements"
require_relative "errors"

module RubyLox
  # Parse the lox grammar, defines as:
  #
  # program        → declaration* EOF ;
  # declaration    → classDecl
  #                | funDecl
  #                | varDecl
  #                | statement ;
  # classDecl      → "class" IDENTIFIER ( "<" IDENTIFIER )? "{" function* "}" ;
  # funDecl        → "fun" function ;
  # function       → IDENTIFIER "(" parameters? ")" block ;
  # parameters     → IDENTIFIER ( "," IDENTIFIER )* ;
  # varDecl        → "var" IDENTIFIER ("=" expression)? ";" ;
  # statement      → exprStmt
  #                | forStmt
  #                | ifStmt
  #                | printStmt
  #                | returnStmt
  #                | whileStmt
  #                | block ;
  # exprStmt       → expression ";" ;
  # forStmt        → "for" "(" ( varDecl | exprStmt | ";" )\
  #                  expression? ";"
  #                  expression? ")" statement;
  # printStmt      → "print" expression ";" ;
  # returnStmt     → "return" expression? ";" ;
  # whileStmt      → "while" "(" expression ")" statement;
  # block          → "{" declaration* "}" ;
  # expression     → assignment ;
  # ifStmt         → "if" "(" expression ")" statement
  #                  ( "else" statement )? ;
  # assignment     → ( call "." )? IDENTIFIER "=" assignment
  #                | logic_or ;
  # logic_or       → logic_and ( "or" logic_and )* ;
  # logic_and      → equality ( "and" equality )* ;
  # equality       → comparison ( ( "!=" | "==" ) comparison )* ;
  # comparison     → term ( ( ">" | ">=" | "<" | "<=" ) term )* ;
  # term           → factor ( ( "-" | "+" ) factor )* ;
  # factor         → unary ( ( "/" | "*" ) unary )* ;
  # unary          → ( "!" | "-" ) unary
  #                | call ;
  # call           → primary ( "(" arguments? ")" | "." IDENTIFIER )* ;
  # primary        → NUMBER | STRING | "true" | "false" | "nil" | "this"
  #                | "(" expression ")" | IDENTIFIER
  #                | "super" "." IDENTIFIER ;
  # arguments      → expression ( "," expression )* ;
  class Parser
    class Error < LoxCompileError
      def initialize(token, message)
        super
        @token = token
        @message = message
      end

      def to_s
        "Error on line #{@token.line}: #{@message}"
      end
    end

    STATEMENT_START_TOKENS = %i[class for fun if print return var while].freeze
    MAX_ARGS = 255

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

    # @return [Array<RubyLox::Statements::*>] An object representing the parsed AST (Abstract Syntax Tree).
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
      return classDeclaration() if match(:class)
      return function("function") if match(:fun)
      return var_declaration if match(:var)

      statement
    rescue Error => e
      @errors << e
      synchronize
      nil
    end

    def classDeclaration
      name = consume(:identifier, "Expect class name.")

      superclass = nil
      if match(:less)
        superclass = Expressions::Variable.new(
          consume(:identifier, "Expect superclass name.")
        )
      end

      consume(:left_brace, "Expect '{' before class body.")

      methods = []
      methods << function("method") while !check(:right_brace) && !is_at_end?

      consume(:right_brace, "Expect '}' before class body.")
      Statements::Class.new(name, superclass, methods)
    end

    def function(kind)
      name = consume(:identifier, "Expect #{kind} name.")

      consume(:left_paren, "Expect ( after #{kind} name.")
      params = parameters
      consume(:right_paren, "Expect ) after #{kind} parameters.")

      consume(:left_brace, "Expect '{' before #{kind} body.")
      body = block

      Statements::Function.new(name, params, body)
    end

    def parameters
      params = []
      return params if check(:right_paren)

      params << consume(:identifier, "Expect parameter name.")
      while match(:comma)
        params << consume(:identifier, "Expect parameter name.")
      end

      if params.size >= MAX_ARGS
        @errors << Error.new(peek, "Can't have more than #{MAX_ARGS} parameters.")
      end

      params
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
      return forStatement if match(:for)
      return ifStatement if match(:if)
      return printStatement if match(:print)
      return returnStatement if match(:return)
      return whileStatement if match(:while)
      return block if match(:left_brace)

      expressionStatement
    end

    def forStatement
      consume(:left_paren, "Expect '(' after for.")

      initializer = if match(:semicolon)
                      nil
                    elsif match(:var)
                      var_declaration
                    else
                      expressionStatement
                    end

      condition = check(:semicolon) ? nil : expression
      consume(:semicolon, "Expect ';' after for loop condition.")

      increment = check(:semicolon) ? nil : expression
      consume(:right_paren, "Expect ')' after for clauses.")

      body = statement

      # Now we have all the pieces and we compose them into a while loop

      if increment
        body = Statements::Block.new([body, Statements::Expression.new(increment)])
      end
      condition ||= expr::Literal.new(true)
      body = Statements::While.new(condition, body)
      if initializer
        body = Statements::Block.new([initializer, body])
      end
      body
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

    def returnStatement
      keyword = previous
      value = check(:semicolon) ? nil : expression
      consume(:semicolon, "Expect ';' after return value.")
      Statements::Return.new(keyword, value)
    end

    def whileStatement
      consume(:left_paren, "Expect '(' after while.")
      condition = expression
      consume(:right_paren, "Expect ')' after while condition.")

      body = statement
      Statements::While.new(condition, body)
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
      expr = logic_or

      if match(:equal)
        equals = previous
        value = assignment

        if expr.is_a?(Expressions::Variable)
          return Expressions::Assign.new(expr.name, value)
        elsif expr.is_a?(Expressions::Get)
          return Expressions::Set.new(expr.object, expr.name, value)
        end

        fail Error.new(equals, "Invalid assignment target.")
      end

      expr
    end

    def logic_or
      expr = logic_and

      while match(:or)
        operator = previous
        right = logic_and

        expr = Expressions::Logical.new(expr, operator, right)
      end

      expr
    end

    def logic_and
      expr = equality

      while match(:and)
        operator = previous
        right = logic_and

        expr = Expressions::Logical.new(expr, operator, right)
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
        call
      end
    end

    def call
      expr = primary

      while true
        if match(:left_paren)
          args = arguments
          consume(:right_paren, "Expect ')' after call arguments.")
          expr = Expressions::Call.new(expr, previous, args)
        elsif match(:dot)
          name = consume(:identifier, "Expect property name after '.'.")
          expr = Expressions::Get.new(expr, name)
        else
          break
        end
      end

      expr
    end

    def arguments
      args = []

      if (!check(:right_paren))
        args << expression
        while match(:comma)
          args << expression
        end
      end

      if args.size >= MAX_ARGS
        @errors << Error.new(peek, "Can't have more than #{MAX_ARGS} arguments.")
      end

      args
    end

    def primary
      return Expressions::Literal.new(false) if match(:false)
      return Expressions::Literal.new(true) if match(:true)
      return Expressions::Literal.new(nil) if match(:nil)

      if match(:number, :string)
        return Expressions::Literal.new(previous.literal)
      end

      if match(:this)
        return Expressions::This.new(previous)
      end

      if match(:identifier)
        return Expressions::Variable.new(previous)
      end

      if match(:left_paren)
        expr = expression
        consume(:right_paren, "Expect ')' after expression.")
        return Expressions::Grouping.new(expr)
      end

      if match(:super)
        keyword = previous
        consume(:dot, "Expect '.' after 'super'.")
        method = consume(:identifier, "Expect superclass method name.")
        return Expressions::Super.new(keyword, method)
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
