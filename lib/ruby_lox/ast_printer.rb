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

    def visitStmtReturn(stmt)
      "(return #{stmt.value&.accept(self)})"
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

    def visitStmtBlock(stmtBlock)
      "{ #{stmtBlock.statements.map { |stmt| stmt.accept(self) }.join(",")} }"
    end

    def visitStmtClass(stmt)
      "(class #{stmt.name.lexeme} #{stmt.methods.map { |method| method.accept(self) }.join(",")})"
    end

    def visitStmtIf(stmt)
      if stmt.elseBranch
        "(if #{stmt.condition.accept(self)} #{stmt.thenBranch.accept(self)} #{stmt.elseBranch.accept(self)})"
      else
        "(if #{stmt.condition.accept(self)} #{stmt.thenBranch.accept(self)})"
      end
    end

    def visitLogical(logical)
      "(#{logical.operator.lexeme} #{logical.left.accept(self)} #{logical.right.accept(self)})"
    end

    def visitStmtWhile(stmt)
      "(while #{stmt.condition.accept(self)} #{stmt.body.accept(self)})"
    end

    def visitCall(expr)
      "(call #{expr.callee.accept(self)} (#{expr.arguments.map { |arg| arg.accept(self) }.join(",")}))"
    end

    def visitStmtFunction(stmt)
      "(fun #{stmt.name.lexeme}(#{stmt.params.map(&:literal).join(",")}) #{stmt.body.accept(self)}"
    end
  end
end
