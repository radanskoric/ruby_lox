# frozen_string_literal: true
require_relative "token"

module RubyLox
  class AstPrinter
    def visitBinary(binary)
      "(#{binary.operator.lexeme} #{binary.left.accept(self)} #{binary.right.accept(self)})"
    end

    def visitGrouping(grouping)
      "(group #{grouping.expression.accept(self)})"
    end

    def visitLiteral(literal)
      (literal.value || "nil").to_s
    end

    def visitUnary(unary)
      "(#{unary.operator.lexeme} #{unary.right.accept(self)})"
    end
  end
end
