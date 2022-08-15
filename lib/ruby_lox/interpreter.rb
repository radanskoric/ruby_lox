# frozen_string_literal: true

module RubyLox
  class Interpreter
    NUMERIC_ONLY_BINARY_OPERATIONS = %i[minus slash star greater greater_equal less less_equal].freeze

    class LoxRuntimeError < RuntimeError
      def initialize(token, message)
        @token = token
        @message = message
      end

      def to_s
        "Runtime error executing \"#{@token.lexeme}\" on line #{@token.line}: #{@message}"
      end
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

    private

    def evaluate(expr)
      expr.accept(self)
    end

    def checkNumberOperand(token, value)
      return if value.is_a? Numeric
      fail LoxRuntimeError.new(token, "Operand must be a number.")
    end

    def checkNumberOperands(token, left, right)
      return if left.is_a?(Numeric) && right.is_a?(Numeric)
      fail LoxRuntimeError.new(token, "Operands must be numbers.")
    end

    def checkAddableOperands(token, left, right)
      return if (left.is_a?(Numeric) && right.is_a?(Numeric))
      return if (left.is_a?(String) && right.is_a?(String))
      fail LoxRuntimeError.new(token, "Operands must be two numbers or two strings.")
    end
  end
end
