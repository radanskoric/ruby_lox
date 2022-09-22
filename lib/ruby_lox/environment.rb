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

    def assign(name, value)
      if @values.key?(name)
        @values[name] = value
      else
        @enclosing ? @enclosing.assign(name, value) : fail_undefined(name)
      end
    end

    private

    def fail_undefined(name)
      fail(LoxRuntimeError.new("Undefined variable '#{name}'."))
    end
  end
end
