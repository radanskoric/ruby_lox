# frozen_string_literal: true
# typed: strict

require_relative "token"

module RubyLox
  class AstPrinter
    extend T::Sig
    sig { params(binary: Expressions::Binary).returns(String) }
    def visitBinary(binary)
      "(#{binary.operator.lexeme} #{binary.left.accept(self)} #{binary.right.accept(self)})"
    end

    sig { params(expr: Expressions::Call).returns(String) }
    def visitCall(expr)
      "(call #{expr.callee.accept(self)} (#{expr.arguments.map { |arg| arg.accept(self) }.join(",")}))"
    end

    sig { params(expr: Expressions::Get).returns(String) }
    def visitGet(expr)
      "(get #{expr.object.accept(self)} #{expr.name.lexeme})"
    end

    sig { params(grouping: Expressions::Grouping).returns(String) }
    def visitGrouping(grouping)
      "(group #{grouping.expression.accept(self)})"
    end

    sig { params(literal: Expressions::Literal).returns(String) }
    def visitLiteral(literal)
      (literal.value || "nil").to_s
    end

    sig { params(logical: Expressions::Logical).returns(String) }
    def visitLogical(logical)
      "(#{logical.operator.lexeme} #{logical.left.accept(self)} #{logical.right.accept(self)})"
    end

    sig { params(expr: Expressions::Set).returns(String) }
    def visitSet(expr)
      "(set #{expr.object.accept(self)} #{expr.name.lexeme} #{expr.value.accept(self)})"
    end

    sig { params(expr: Expressions::Super).returns(String) }
    def visitSuper(expr)
      "(super #{expr.method.accept(self)})"
    end

    sig { params(expr: Expressions::This).returns(String) }
    def visitThis(expr)
      "(this)"
    end

    sig { params(unary: Expressions::Unary).returns(String) }
    def visitUnary(unary)
      "(#{unary.operator.lexeme} #{unary.right.accept(self)})"
    end

    sig { params(variable: Expressions::Variable).returns(String) }
    def visitVariable(variable)
      variable.name || "undefined"
    end

    sig { params(expr: Expressions::Assign).returns(String) }
    def visitAssign(expr)
      "(= #{expr.name} #{expr.value.accept(self)})"
    end

    sig { params(stmt: Statements::Expression).returns(String) }
    def visitStmtExpression(stmt)
      "(expr #{stmt.expression.accept(self)})"
    end

    sig { params(stmt: Statements::Function).returns(String) }
    def visitStmtFunction(stmt)
      "(fun #{stmt.name.lexeme}(#{stmt.params.map(&:literal).join(",")}) #{stmt.body.accept(self)}"
    end

    sig { params(stmt: Statements::Print).returns(String) }
    def visitStmtPrint(stmt)
      "(print #{stmt.expression.accept(self)})"
    end

    sig { params(stmt: Statements::Return).returns(String) }
    def visitStmtReturn(stmt)
      "(return #{stmt.value&.accept(self)})"
    end

    sig { params(stmt: Statements::VarDecl).returns(String) }
    def visitStmtVarDecl(stmt)
      if stmt.initializer
        "(var #{stmt.name.lexeme} #{stmt.initializer.accept(self)})"
      else
        "(var #{stmt.name.lexeme})"
      end
    end

    sig { params(stmtBlock: Statements::Block).returns(String) }
    def visitStmtBlock(stmtBlock)
      "{ #{stmtBlock.statements.map { |stmt| stmt.accept(self) }.join(",")} }"
    end

    sig { params(stmt: Statements::Class).returns(String) }
    def visitStmtClass(stmt)
      "(class #{stmt.name.lexeme} #{stmt.methods.map { |method| method.accept(self) }.join(",")})"
    end

    sig { params(stmt: Statements::If).returns(String) }
    def visitStmtIf(stmt)
      if stmt.elseBranch
        "(if #{stmt.condition.accept(self)} #{stmt.thenBranch.accept(self)} #{stmt.elseBranch.accept(self)})"
      else
        "(if #{stmt.condition.accept(self)} #{stmt.thenBranch.accept(self)})"
      end
    end

    sig { params(stmt: Statements::While).returns(String) }
    def visitStmtWhile(stmt)
      "(while #{stmt.condition.accept(self)} #{stmt.body.accept(self)})"
    end
  end
end
