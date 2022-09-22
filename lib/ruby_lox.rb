# frozen_string_literal: true

require_relative "ruby_lox/version"
require_relative "ruby_lox/scanner"
require_relative "ruby_lox/parser"
require_relative "ruby_lox/interpreter"

module RubyLox
  class Error < StandardError; end

  class Runner
    def initialize
      @interpreter = Interpreter.new
    end

    def run(source)
      scanner = RubyLox::Scanner.new(source)
      tokens = scanner.scan_tokens
      if scanner.error?
        puts "There were lexical errors:"
        scanner.errors.each { |err| puts "  #{err}" }
        return
      end

      parser = RubyLox::Parser.new(tokens)
      ast = parser.parse
      if parser.error?
        puts "There were syntax errors:"
        parser.errors.each { |err| puts "  #{err}" }
        return
      end

      begin
        @interpreter.interpret(ast)
      rescue LoxRuntimeError => e
        puts e
      end
    end
  end
end
