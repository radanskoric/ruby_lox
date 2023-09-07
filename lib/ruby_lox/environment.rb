# frozen_string_literal: true
# typed: strict

require_relative "errors"

module RubyLox
  class Environment
    extend T::Sig
    sig { returns(T.nilable(T.self_type)) }
    attr_reader :enclosing

    # Can't use T.self_type because of a bug in Sorbet: https://github.com/sorbet/sorbet/issues/5631
    sig { params(enclosing: T.nilable(Environment)).void }
    def initialize(enclosing = nil)
      @values = T.let({}, T::Hash[T.untyped, T.untyped])
      @enclosing = enclosing
    end

    sig { params(name: String, value: T.untyped).returns(T.untyped) }
    def define(name, value)
      @values[name] = value
    end

    sig { params(name: String).returns(T.untyped) }
    def get(name)
      @values[name] || (@enclosing ? @enclosing.get(name) : fail_undefined(name))
    end

    sig { params(distance: Integer, name: String).returns(T.untyped) }
    def getAt(distance, name)
      if distance.zero?
        @values[name] || fail_undefined(name)
      else
        @enclosing ? @enclosing.getAt(distance - 1, name) : fail_undefined(name)
      end
    end

    sig { params(name: String, value: T.untyped).returns(T.untyped) }
    def assign(name, value)
      if @values.key?(name)
        @values[name] = value
      else
        @enclosing ? @enclosing.assign(name, value) : fail_undefined(name)
      end
    end

    sig { params(distance: Integer, name: String, value: T.untyped).void }
    def assignAt(distance, name, value)
      if distance.zero?
        @values.key?(name) ? @values[name] = value : fail_undefined(name)
      else
        @enclosing ? @enclosing.assignAt(distance - 1, name, value) : fail_undefined(name)
      end
    end

    private

    sig { params(name: String).void }
    def fail_undefined(name)
      fail(LoxRuntimeError.new("Undefined variable '#{name}'."))
    end
  end
end
