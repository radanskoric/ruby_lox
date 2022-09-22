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

    def visitVariable(variable)
      variable.name || "undefined"
    end

    def visitStmtExpression(stmt)
      "(expr #{stmt.expression.accept(self)})"
    end

    def visitStmtPrint(stmt)
      "(print #{stmt.expression.accept(self)})"
    end

    def visitStmtVarDecl(stmt)
      if stmt.initializer
        "(var #{stmt.name.lexeme} #{stmt.initializer.accept(self)})"
      else
        "(var #{stmt.name.lexeme})"
      end
    end

    def visitAssign(expr)
      "(= #{expr.name} #{expr.value.accept(self)})"
    end

    def visitStmtBlock(stmt)
      "{ #{stmt.statements.map { |stmt| stmt.accept(self) }.join(",")} }"
    end
  end
end
