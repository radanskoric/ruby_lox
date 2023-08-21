# frozen_string_literal: true

require_relative "errors"

module RubyLox
  # Implements an additional pass after parsing that resolves variable
  # lookup. It enables static as opposed to dynamic lookup.
  class Resolver
    class Error < LoxCompileError; end

    # In the book, jlox uses an enum. Here a hash will pretend it's an enum.
    FUNCTION_TYPE = {
      none: 0,
      function: 1
    }.freeze

    def initialize(interpreter)
      @interpreter = interpreter
      @scopes = []
      @currentFunction = FUNCTION_TYPE[:none]
    end

    def resolve(statement_or_statements)
      if statement_or_statements.is_a?(Array)
        statement_or_statements.each do |stmt|
          stmt.accept(self)
        end
      else
        statement_or_statements.accept(self)
      end
    end

    def visitBinary(binary)
      resolve(binary.left)
      resolve(binary.right)
    end

    def visitGrouping(grouping)
      resolve(grouping.expression)
    end

    def visitLiteral(literal)
      # no op
    end

    def visitUnary(unary)
      resolve(unary.right)
    end

    def visitVariable(variable)
      if @scopes.any? && @scopes.last[variable.name] == false
        fail LoxCompilerError.new(variable.name, "Can't read local variable in its own initializer.")
      end

      resolveLocal(variable, variable.name)
    end

    def visitStmtExpression(stmt)
      resolve(stmt.expression)
    end

    def visitStmtPrint(stmt)
      resolve(stmt.expression)
    end

    def visitStmtReturn(stmt)
      fail(Error.new(stmt.keyword, "Can't return from top-level code.")) if @currentFunction == FUNCTION_TYPE[:none]

      resolve(stmt.value) if stmt.value
    end

    def visitStmtWhile(stmt)
      resolve(stmt.condition)
      resolve(stmt.body)
    end

    def visitStmtVarDecl(stmt)
      declare stmt.name
      # binding.break
      resolve(stmt.initializer) if stmt.initializer
      define stmt.name
    end

    def visitAssign(expr)
      resolve(expr.value)
      resolveLocal(expr, expr.name)
    end

    def visitStmtBlock(block)
      beginScope
      resolve block.statements
      endScope
    end

    def visitStmtClass(stmt)
      declare(stmt.name)
      define(stmt.name)
    end

    def visitStmtIf(stmt)
      resolve(stmt.condition)
      resolve(stmt.thenBranch)
      resolve(stmt.elseBranch) if stmt.elseBranch
    end

    def visitLogical(expr)
      resolve(expr.left)
      resolve(expr.right)
    end

    def visitCall(expr)
      resolve(expr.callee)
      expr.arguments.each { |arg| resolve(arg) }
    end

    def visitStmtFunction(stmt)
      declare(stmt.name)
      define(stmt.name)
      resolveFunction(stmt, FUNCTION_TYPE[:function])
    end

    private

    def beginScope
      @scopes.push({})
    end

    def endScope
      @scopes.pop
    end

    def declare(name)
      return if @scopes.empty?

      fail(Error.new(name, "Already a variable with this name in this scope.")) if @scopes.last.key?(name)

      @scopes.last[name] = false
    end

    def define(name)
      return if @scopes.empty?

      @scopes.last[name] = true
    end

    def resolveLocal(expr, name)
      _scope, index = @scopes.reverse_each.with_index.find { |scope, _index| scope.key?(name) }
      @interpreter.resolve(expr, index) if index
    end

    def resolveFunction(function, type)
      enclosingFunction = @currentFunction
      @currentFunction = type

      beginScope
      function.params.each do |param|
        declare(param)
        define(param)
      end
      resolve(function.body)
      endScope

      @currentFunction = enclosingFunction
    end
  end
end
