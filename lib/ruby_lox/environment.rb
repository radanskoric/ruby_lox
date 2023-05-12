# frozen_string_literal: true

require_relative "errors"

module RubyLox
  class Environment
    def initialize(enclosing = nil)
      @values = {}
      @enclosing = enclosing
    end

    def define(name, value)
      @values[name] = value
    end

    def get(name)
      @values[name] || (@enclosing ? @enclosing.get(name) : fail_undefined(name))
    end

    def getAt(distance, name)
      if distance.zero?
        @values[name] || fail_undefined(name)
      else
        @enclosing ? @enclosing.getAt(distance - 1, name) : fail_undefined(name)
      end
    end

    def assign(name, value)
      if @values.key?(name)
        @values[name] = value
      else
        @enclosing ? @enclosing.assign(name, value) : fail_undefined(name)
      end
    end

    def assignAt(distance, name, value)
      if distance.zero?
        @values.key?(name) ? @values[name] = value : fail_undefined(name)
      else
        @enclosing ? @enclosing.assignAt(distance - 1, name, value) : fail_undefined(name)
      end
    end

    private

    def fail_undefined(name)
      fail(LoxRuntimeError.new("Undefined variable '#{name}'."))
    end
  end
end
