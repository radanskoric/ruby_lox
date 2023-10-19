# frozen_string_literal: true
# typed: strict

require_relative "errors"

module RubyLox
  # Implements an additional pass after parsing that resolves variable
  # lookup. It enables static as opposed to dynamic lookup.
  class Resolver
    extend T::Sig
    class Error < LoxCompileError; end

    # In the book, jlox uses an enum. Here a hash will pretend it's an enum.
    FUNCTION_TYPE = T.let({
      none: 0,
      function: 1,
      initializer: 2,
      method: 3,
    }.freeze, T::Hash[Symbol, Integer])

    CLASS_TYPE = T.let({
      none: 0,
      class: 1,
      subclass: 2,
    }.freeze, T::Hash[Symbol, Integer])

    sig { params(interpreter: Interpreter).void }
    def initialize(interpreter)
      @interpreter = interpreter
      @scopes = T.let([], T::Array[T::Hash[String, T::Boolean]])
      @currentFunction = T.let(T.must(FUNCTION_TYPE[:none]), Integer)
      @currentClass = T.let(T.must(CLASS_TYPE[:none]), Integer)
    end

    sig { params(statement_or_statements: T.any(T.untyped, T::Array[T.untyped])).void }
    def resolve(statement_or_statements)
      if statement_or_statements.is_a?(Array)
        statement_or_statements.each do |stmt|
          stmt.accept(self)
        end
      else
        statement_or_statements.accept(self)
      end
    end

    sig { params(binary: Expressions::Binary).void }
    def visitBinary(binary)
      resolve(binary.left)
      resolve(binary.right)
    end

    sig { params(grouping: Expressions::Grouping).void }
    def visitGrouping(grouping)
      resolve(grouping.expression)
    end

    sig { params(literal: T.untyped).void }
    def visitLiteral(literal)
      # no op
    end

    sig { params(variable: Expressions::Variable).void }
    def visitVariable(variable)
      if @scopes.any? && T.must(@scopes.last)[variable.name.lexeme] == false
        fail Error.new(variable.name, "Can't read local variable in its own initializer.")
      end

      resolveLocal(variable, variable.name)
    end

    sig { params(stmt: Statements::Expression).void }
    def visitStmtExpression(stmt)
      resolve(stmt.expression)
    end

    sig { params(stmt: Statements::Print).void }
    def visitStmtPrint(stmt)
      resolve(stmt.expression)
    end

    sig { params(stmt: Statements::Return).void }
    def visitStmtReturn(stmt)
      fail(Error.new(stmt.keyword, "Can't return from top-level code.")) if @currentFunction == FUNCTION_TYPE[:none]

      fail(Error.new(stmt.keyword,
                     "Can't return a value from an initializer.")) if @currentFunction == FUNCTION_TYPE[:initializer]

      resolve(stmt.value) if stmt.value
    end

    sig { params(stmt: Statements::While).void }
    def visitStmtWhile(stmt)
      resolve(stmt.condition)
      resolve(stmt.body)
    end

    sig { params(stmt: Statements::VarDecl).void }
    def visitStmtVarDecl(stmt)
      declare stmt.name
      resolve(stmt.initializer) if stmt.initializer
      define stmt.name
    end

    sig { params(expr: Expressions::Assign).void }
    def visitAssign(expr)
      resolve(expr.value)
      resolveLocal(expr, expr.name)
    end

    sig { params(block: Statements::Block).void }
    def visitStmtBlock(block)
      beginScope
      resolve block.statements
      endScope
    end

    sig { params(stmt: Statements::Class).void }
    def visitStmtClass(stmt)
      enclosingClass = T.let(@currentClass, Integer)
      @currentClass = T.must(CLASS_TYPE[:class])

      declare(stmt.name)
      define(stmt.name)

      if stmt.superclass
        if stmt.name.lexeme == stmt.superclass.name.lexeme
          fail(Error.new(stmt.superclass.name, "A class can't inherit from itself."))
        else
          @currentClass = T.must(CLASS_TYPE[:subclass])
          resolve(stmt.superclass)

          beginScope
          T.must(@scopes.last)["super"] = true
        end
      end

      beginScope
      T.must(@scopes.last)["this"] = true

      stmt.methods.each do |method|
        resolveFunction(method, T.must(FUNCTION_TYPE[method.name.lexeme == "init" ? :initializer : :method]))
      end

      endScope

      endScope if stmt.superclass

      @currentClass = enclosingClass
    end

    sig { params(stmt: Statements::If).void }
    def visitStmtIf(stmt)
      resolve(stmt.condition)
      resolve(stmt.thenBranch)
      resolve(stmt.elseBranch) if stmt.elseBranch
    end

    sig { params(expr: Expressions::Logical).void }
    def visitLogical(expr)
      resolve(expr.left)
      resolve(expr.right)
    end

    sig { params(expr: Expressions::Set).void }
    def visitSet(expr)
      resolve(expr.value)
      resolve(expr.object)
    end

    sig { params(expr: Expressions::Super).void }
    def visitSuper(expr)
      if @currentClass == CLASS_TYPE[:none]
        fail(Error.new(expr.keyword, "Can't use 'super' outside of a class."))
      elsif @currentClass != CLASS_TYPE[:subclass]
        fail(Error.new(expr.keyword, "Can't use 'super' in a class with no superclass."))
      end

      resolveLocal(expr, expr.keyword)
    end

    sig { params(expr: Expressions::This).void }
    def visitThis(expr)
      if @currentClass == CLASS_TYPE[:none]
        fail(Error.new(expr.keyword, "Can't use 'this' outside of a class."))
      end

      resolveLocal(expr, expr.keyword)
    end

    sig { params(unary: Expressions::Unary).void }
    def visitUnary(unary)
      resolve(unary.right)
    end

    sig { params(expr: Expressions::Call).void }
    def visitCall(expr)
      resolve(expr.callee)
      expr.arguments.each { |arg| resolve(arg) }
    end

    sig { params(expr: Expressions::Get).void }
    def visitGet(expr)
      resolve(expr.object)
    end

    sig { params(stmt: Statements::Function).void }
    def visitStmtFunction(stmt)
      declare(stmt.name)
      define(stmt.name)
      resolveFunction(stmt, T.must(FUNCTION_TYPE[:function]))
    end

    private

    sig { void }
    def beginScope
      @scopes.push({})
    end

    sig { void }
    def endScope
      @scopes.pop
    end

    sig { params(name: Token).void }
    def declare(name)
      return if @scopes.empty?

      fail(Error.new(name, "Already a variable with this name in this scope.")) if T.must(@scopes.last).key?(name.lexeme)

      T.must(@scopes.last)[name.lexeme] = false
    end

    sig { params(name: Token).void }
    def define(name)
      return if @scopes.empty?

      T.must(@scopes.last)[name.lexeme] = true
    end

    sig { params(expr: Expressions::SORBET_ANY, name: Token).void }
    def resolveLocal(expr, name)
      _scope, index = @scopes.reverse_each.with_index.find { |scope, _index| scope.key?(name.lexeme) }
      @interpreter.resolve(expr, index) if index
    end

    sig { params(function: Statements::Function, type: Integer).void }
    def resolveFunction(function, type)
      enclosingFunction = T.let(@currentFunction, Integer)
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
