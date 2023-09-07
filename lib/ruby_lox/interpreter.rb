# frozen_string_literal: true
# typed: strict

require "stringio"

require_relative "errors"
require_relative "environment"

module RubyLox
  class Interpreter
    extend T::Sig
    NUMERIC_ONLY_BINARY_OPERATIONS = T.let(%i[minus slash star greater greater_equal less less_equal].freeze, T::Array[Symbol])

    class SemanticError < LoxRuntimeError
      sig { params(token: Token, message: String).void }
      def initialize(token, message)
        super(message)
        @token = token
      end

      sig { returns(String) }
      def to_s
        "Runtime error executing \"#{@token.lexeme}\" on line #{@token.line}: #{@message}"
      end
    end

    class ReturnValue < RuntimeError
      extend T::Sig

      sig { returns(T.untyped) }
      attr_reader :value

      sig { params(value: T.untyped).void }
      def initialize(value)
        super()
        @value = value
      end
    end

    class LoxFunction
      extend T::Sig
      # @param declaration [RubyLox::Statements::Function]
      # @param closure [RubyLox::Environment]
      # @param isInitializer [Boolean]
      sig { params(declaration: Statements::Function, closure: Environment, isInitializer: T::Boolean).void }
      def initialize(declaration, closure, isInitializer)
        @declaration = declaration
        @closure = closure
        @isInitializer = isInitializer
      end

      sig { params(instance: LoxInstance).returns(T.self_type) }
      def bind(instance)
        env = Environment.new(@closure)
        env.define("this", instance)
        self.class.new(@declaration, env, @isInitializer)
      end

      sig { params(interpreter: Interpreter, arguments: T::Array[T.untyped]).returns(T.untyped) }
      def call(interpreter, arguments)
        env = Environment.new(@closure)
        @declaration.params.each_with_index do |param, index|
          env.define(param.lexeme, arguments.fetch(index))
        end

        interpreter.executeBlock(@declaration.body, Environment.new(env))
        return @closure.getAt(0, "this") if @isInitializer

        nil
      rescue ReturnValue => e
        return @closure.getAt(0, "this") if @isInitializer

        e.value
      end

      sig { returns(Integer) }
      def arity
        @declaration.params.size
      end

      sig { returns(String) }
      def to_s
        "<fn #{@declaration.name.lexeme}>"
      end
    end

    class ClockFunction
      extend T::Sig
      sig { returns(Integer) }
      def arity
        0
      end

      sig { params(_interpreter: Interpreter, _args: T::Array[T.untyped]).returns(Float) }
      def call(_interpreter, _args)
        Time.now.to_f
      end

      sig { returns(String) }
      def to_s
        "<native fn clock>"
      end
    end

    class LoxClass
      extend T::Sig
      # @param name [String]
      # @param superclass [LoxClass, nil]
      # @param methods [Hash<String, LoxFunction>]
      sig { params(name: String, superclass: T.nilable(LoxClass), methods: T::Hash[T.untyped, T.untyped]).void }
      def initialize(name, superclass, methods)
        @name = name
        @superclass = superclass
        @methods = methods
      end

      sig { returns(String) }
      def to_s
        @name
      end

      sig { params(interpreter: Interpreter, arguments: T.untyped).returns(RubyLox::Interpreter::LoxInstance) }
      def call(interpreter, arguments)
        instance = LoxInstance.new(self)

        initializer = findMethod("init")
        initializer.bind(instance).call(interpreter, arguments) if initializer

        instance
      end

      sig { returns(Integer) }
      def arity
        initializer = findMethod("init")
        initializer ? initializer.arity : 0
      end

      sig { params(name: String).returns(T.nilable(LoxFunction)) }
      def findMethod(name)
        if @methods.key?(name)
          @methods[name]
        else
          @superclass&.findMethod(name)
        end
      end
    end

    class LoxInstance
      extend T::Sig
      # @param klass [LoxClass]
      sig { params(klass: LoxClass).void }
      def initialize(klass)
        @klass = klass
        @fields = T.let({}, T::Hash[T.untyped, T.untyped])
      end

      sig { returns(String) }
      def to_s
        "#{@klass} instance"
      end

      sig { params(name: Token).returns(T.untyped) }
      def get(name)
        if @fields.key?(name.literal)
          return @fields[name.literal]
        end

        @klass.findMethod(name.lexeme)&.bind(self) ||
          fail(SemanticError.new(name, "Undefined property '#{name.lexeme}'."))
      end

      sig { params(name: Token, value: T.untyped).returns(T.untyped) }
      def set(name, value)
        @fields[name.literal] = value
      end
    end

    sig { returns(T.nilable(Environment)) }
    attr_reader :environment

    sig { params(out: T.any(IO, StringIO)).void }
    def initialize(out = STDOUT)
      @out = out
      @environment = T.let(Environment.new, T.nilable(RubyLox::Environment))
      @globals = T.let(T.must(@environment), RubyLox::Environment)
      T.must(@environment).define("clock", ClockFunction.new)
      @locals = T.let({}, T::Hash[T.untyped, T.untyped])
    end

    sig { params(program: T::Array[T.untyped]).returns(NilClass) }
    def interpret(program)
      program.each { |stmt| stmt.accept(self) }
      nil
    end

    sig { params(binary: Expressions::Binary).returns(T.untyped) }
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

    sig { params(grouping: Expressions::Grouping).returns(T.untyped) }
    def visitGrouping(grouping)
      evaluate(grouping.expression)
    end

    sig { params(literal: Expressions:: Literal).returns(T.untyped) }
    def visitLiteral(literal)
      literal.value
    end

    sig { params(variable: Expressions::Variable).returns(T.untyped) }
    def visitVariable(variable)
      lookUpVariable(variable.name, variable)
    end

    sig { params(stmt: Statements::Expression).void }
    def visitStmtExpression(stmt)
      evaluate(stmt.expression)
      nil
    end

    sig { params(stmt: Statements::Print).void }
    def visitStmtPrint(stmt)
      output = evaluate(stmt.expression).to_s
      output.delete_suffix!(".0") if output.end_with?(".0")
      @out.puts output
      nil
    end

    sig { params(stmt: Statements::Return).void }
    def visitStmtReturn(stmt)
      value = stmt.value ? evaluate(stmt.value) : nil
      raise ReturnValue.new(value)
    end

    sig { params(stmt: Statements::While).void }
    def visitStmtWhile(stmt)
      evaluate(stmt.body) while evaluate(stmt.condition)
      nil
    end

    sig { params(stmt: Statements::VarDecl).void }
    def visitStmtVarDecl(stmt)
      value = stmt.initializer ? evaluate(stmt.initializer) : nil
      T.must(@environment).define(stmt.name.lexeme, value)
      nil
    end

    sig { params(expr: Expressions::Assign).returns(T.untyped) }
    def visitAssign(expr)
      value = evaluate(expr.value)
      assignVariable(expr.name, expr, value)
      nil
    end

    sig { params(block: Statements::Block).void }
    def visitStmtBlock(block)
      executeBlock(block, Environment.new(@environment))
      nil
    end

    sig { params(stmt: Statements::Class).void }
    def visitStmtClass(stmt)
      T.must(@environment).define(stmt.name.lexeme, nil)

      superclass = nil
      if stmt.superclass
        superclass = evaluate(stmt.superclass)
        unless superclass.is_a?(LoxClass)
          fail SemanticError.new(stmt.superclass.name, "Superclass must be a class.")
        end

        @environment = T.let(Environment.new(@environment), T.nilable(RubyLox::Environment))
        T.must(@environment).define("super", superclass)
      end

      methods = stmt.methods.each_with_object({}) do |method, hash|
        fnName = method.name.lexeme
        hash[fnName] = LoxFunction.new(method, T.must(@environment), fnName == "init")
      end

      klass = LoxClass.new(stmt.name.lexeme, superclass, methods)

      @environment = T.must(T.let(T.must(@environment), Environment).enclosing) if stmt.superclass

      T.must(@environment).assign(stmt.name.lexeme, klass)
    end

    sig { params(stmt: Statements::If).void }
    def visitStmtIf(stmt)
      if evaluate(stmt.condition)
        evaluate(stmt.thenBranch)
      elsif stmt.elseBranch
        evaluate(stmt.elseBranch)
      end
    end

    sig { params(expr: Expressions::Logical).returns(T.untyped) }
    def visitLogical(expr)
      left = evaluate(expr.left)

      if expr.operator.type == :or
        return left if left
      else
        return left unless left
      end

      evaluate(expr.right)
    end

    sig { params(expr: Expressions::Set).returns(T.untyped) }
    def visitSet(expr)
      object = evaluate(expr.object)

      unless object.is_a?(LoxInstance)
        fail SemanticError.new(expr.name, "Only instances have fields.")
      end

      value = evaluate(expr.value)
      object.set(expr.name, value)
      value
    end

    sig { params(expr: Expressions::Super).returns(T.untyped) }
    def visitSuper(expr)
      distance = @locals[expr]

      superclass = T.must(@environment).getAt(distance, "super")
      object = T.must(@environment).getAt(distance - 1, "this")
      method = superclass.findMethod(expr.method.lexeme)

      fail SemanticError.new(expr.method, "Undefined property #{expr.method.lexeme}") unless method

      method.bind(object)
    end

    sig { params(expr: Expressions::This).returns(T.untyped) }
    def visitThis(expr)
      lookUpVariable(expr.keyword, expr)
    end

    sig { params(unary: Expressions::Unary).returns(T.untyped) }
    def visitUnary(unary)
      value = evaluate(unary.right)

      case unary.operator.type
      when :bang then !value
      when :minus then
        checkNumberOperand(unary.operator, value)
        -value
      end
    end

    sig { params(expr: Expressions::Call).returns(T.untyped) }
    def visitCall(expr)
      callee = evaluate(expr.callee)
      arguments = expr.arguments.map { |arg| evaluate(arg) }

      checkValueIsCallable(expr.paren, callee)
      checkArityMatches(expr.paren, callee, arguments)
      callee.call(self, arguments)
    end

    sig { params(expr: Expressions::Get).returns(T.untyped) }
    def visitGet(expr)
      object = evaluate(expr.object)
      if (object.is_a?(LoxInstance))
        return object.get(expr.name)
      end

      fail SemanticError.new(expr.name, "Only instances have properties.")
    end

    sig { params(stmt: Statements::Function).void }
    def visitStmtFunction(stmt)
      function = LoxFunction.new(stmt, T.must(@environment), false)
      T.must(@environment).define(stmt.name.lexeme, function)
      nil
    end

    # Public so it would be accessible by function objects.
    sig { params(block: Statements::Block, environment: Environment).void }
    def executeBlock(block, environment)
      previous = @environment
      @environment = environment
      block.statements.each { |stmt| stmt.accept(self) }
    ensure
      @environment = T.must(previous)
    end

    sig { params(expr: T.untyped, depth: Integer).void }
    def resolve(expr, depth)
      @locals[expr] = depth
    end

    private

    sig { params(expr: T.untyped).returns(T.untyped) }
    def evaluate(expr)
      expr.accept(self)
    end

    sig { params(name: Token, expr: T.untyped).returns(T.untyped) }
    def lookUpVariable(name, expr)
      distance = @locals[expr]
      distance ? T.must(@environment).getAt(distance, name.lexeme) : @globals.get(name.lexeme)
    end

    sig { params(name: Token, expr: T.untyped, value: T.untyped).void }
    def assignVariable(name, expr, value)
      distance = @locals[expr]
      distance ? T.must(@environment).assignAt(distance, name.lexeme, value) : @globals.assign(name.lexeme, value)
    end

    sig { params(token: Token, value: T.untyped).void }
    def checkNumberOperand(token, value)
      return if value.is_a? Numeric

      fail SemanticError.new(token, "Operand must be a number.")
    end

    sig { params(token: Token, left: T.untyped, right: T.untyped).returns(NilClass) }
    def checkNumberOperands(token, left, right)
      return if left.is_a?(Numeric) && right.is_a?(Numeric)

      fail SemanticError.new(token, "Operands must be numbers.")
    end

    sig { params(token: Token, left: T.untyped, right: T.untyped).returns(NilClass) }
    def checkAddableOperands(token, left, right)
      return if left.is_a?(Numeric) && right.is_a?(Numeric)
      return if left.is_a?(String) && right.is_a?(String)

      fail SemanticError.new(token, "Operands must be two numbers or two strings.")
    end

    sig { params(token: Token, value: T.untyped).returns(NilClass) }
    def checkValueIsCallable(token, value)
      return if value.respond_to?(:call) && value.respond_to?(:arity)

      fail SemanticError.new(token, "Can only call functions and classes.")
    end

    sig { params(token: Token, fn: T.untyped, arguments: T.untyped).returns(NilClass) }
    def checkArityMatches(token, fn, arguments)
      return if fn.arity == arguments.size

      fail SemanticError.new(token, "Expected #{fn.arity} arguments but got #{arguments.size}.")
    end
  end
end
