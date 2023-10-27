# frozen_string_literal: true

require_relative "ruby_lox/version"
require_relative "ruby_lox/scanner"
require_relative "ruby_lox/parser"
require_relative "ruby_lox/resolver"
require_relative "ruby_lox/interpreter"

module RubyLox
  class Error < StandardError; end

  class Runner
    def initialize(out = STDOUT)
      @out = out
      @interpreter = Interpreter.new(@out)
    end

    def run(source)
      scanner = RubyLox::Scanner.new(source)
      tokens = scanner.scan_tokens
      if scanner.error?
        @out.puts "There were lexical errors:"
        scanner.errors.each { |err| @out.puts "  #{err}" }
        return
      end

      parser = RubyLox::Parser.new(tokens)
      ast = parser.parse
      if parser.error?
        @out.puts "There were syntax errors:"
        parser.errors.each { |err| @out.puts "  #{err}" }
        return
      end

      begin
        resolver = RubyLox::Resolver.new(@interpreter)
        resolver.resolve(ast)
      rescue LoxCompileError => e
        @out.puts e
        return
      end

      begin
        @interpreter.interpret(ast)
      rescue LoxRuntimeError => e
        @out.puts e
      end
    end
  end
end
