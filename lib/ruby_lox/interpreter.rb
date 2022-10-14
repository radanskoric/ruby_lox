# frozen_string_literal: true

require_relative "errors"
require_relative "environment"

module RubyLox
  class Interpreter
    NUMERIC_ONLY_BINARY_OPERATIONS = %i[minus slash star greater greater_equal less less_equal].freeze

    class SemanticError < LoxRuntimeError
      def initialize(token, message)
        super(message)
        @token = token
      end

      def to_s
        "Runtime error executing \"#{@token.lexeme}\" on line #{@token.line}: #{@message}"
      end
    end

    def initialize(out = STDOUT)
      @out = out
      @environment = Environment.new
      @environment.define("clock", Object.new.tap do |obj|
        def obj.arity
          0
        end

        def obj.call(_interpreter, _args)
          Time.now.to_f
        end

        def obj.to_s
          "<native fn clock>"
        end
      end)
    end

    def interpret(program)
      program.each { |stmt| stmt.accept(self) }
      nil
    end

    def visitBinary(binary)
      left = evaluate(binary.left)
      right = evaluate(binary.right)

      if NUMERIC_ONLY_BINARY_OPERATIONS.include?(binary.operator.type)
        checkNumberOperands(binary.operator, left, right)
      end

      # I'm very lucky here that Lox operands happen to behave the same
      # way as Ruby ones so I get the correct behaviour for free.
      case binary.operator.type
        when :minus then left - right
        when :slash then left / right
        when :star then left * right
        when :plus then
          checkAddableOperands(binary.operator, left, right)
          left + right
        when :greater then left > right
        when :greater_equal then left >= right
        when :less then left < right
        when :less_equal then left <= right
        when :bang_equal then left != right
        when :equal_equal then left == right
      end
    end

    def visitGrouping(grouping)
      evaluate(grouping.expression)
    end

    def visitLiteral(literal)
      literal.value
    end

    def visitUnary(unary)
      value = evaluate(unary.right)

      case unary.operator.type
        when :bang then !value
        when :minus then
          checkNumberOperand(unary.operator, value)
          -value
      end
    end

    def visitVariable(variable)
      @environment.get(variable.name)
    end

    def visitStmtExpression(stmt)
      evaluate(stmt.expression)
      nil
    end

    def visitStmtPrint(stmt)
      output = evaluate(stmt.expression).to_s
      output.delete_suffix!(".0") if output.end_with?(".0")
      @out.puts output
      nil
    end

    def visitStmtWhile(stmt)
      evaluate(stmt.body) while evaluate(stmt.condition)
      nil
    end

    def visitStmtVarDecl(stmt)
      value = stmt.initializer ? evaluate(stmt.initializer) : nil
      @environment.define(stmt.name.lexeme, value)
      nil
    end

    def visitAssign(expr)
      value = evaluate(expr.value)
      @environment.assign(expr.name, value)
      nil
    end

    def visitStmtBlock(block)
      executeBlock(block.statements, Environment.new(@environment))
      nil
    end

    def visitStmtIf(stmt)
      if evaluate(stmt.condition)
        evaluate(stmt.thenBranch)
      else
        evaluate(stmt.elseBranch)
      end
    end

    def visitLogical(expr)
      left = evaluate(expr.left)

      if expr.operator.type == :or
        return left if left
      else
        return left unless left
      end

      evaluate(expr.right)
    end

    def visitCall(expr)
      callee = evaluate(expr.callee)
      arguments = expr.arguments.map { |arg| evaluate(arg) }

      checkValueIsCallable(expr.paren, callee)
      checkArityMatches(expr.paren, callee, arguments)
      callee.call(self, arguments)
    end

    private

    def evaluate(expr)
      expr.accept(self)
    end

    def executeBlock(statements, environment)
      begin
        previous = @environment
        @environment = environment
        statements.each { |stmt| stmt.accept(self) }
      ensure
        @environment = previous
      end
    end

    def checkNumberOperand(token, value)
      return if value.is_a? Numeric
      fail SemanticError.new(token, "Operand must be a number.")
    end

    def checkNumberOperands(token, left, right)
      return if left.is_a?(Numeric) && right.is_a?(Numeric)
      fail SemanticError.new(token, "Operands must be numbers.")
    end

    def checkAddableOperands(token, left, right)
      return if (left.is_a?(Numeric) && right.is_a?(Numeric))
      return if (left.is_a?(String) && right.is_a?(String))
      fail SemanticError.new(token, "Operands must be two numbers or two strings.")
    end

    def checkValueIsCallable(token, value)
      return if value.respond_to?(:call) && value.respond_to?(:arity)
      fail SemanticError.new(token, "Can only call functions and classes.")
    end

    def checkArityMatches(token, fn, arguments)
      return if fn.arity == arguments.size
      fail SemanticError.new(token, "Expected #{fn.arity} arguments but got #{arguments.size}.")
    end
  end
end
