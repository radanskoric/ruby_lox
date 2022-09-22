# frozen_string_literal: true

require_relative "errors"

module RubyLox
  class Environment
    def initialize
      @values = {}
    end

    def define(name, value)
      @values[name] = value
    end

    def get(name)
      @values[name] || fail(LoxRuntimeError.new("Undefined variable '#{name}'."))
    end
  end
end
