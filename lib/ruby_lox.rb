# frozen_string_literal: true

require_relative "ruby_lox/version"
require_relative "ruby_lox/scanner"

module RubyLox
  class Error < StandardError; end

  class Runner
    def initialize
    end

    def run(source)
      scanner = RubyLox::Scanner.new(source)
      tokens = scanner.scan_tokens

      if scanner.error?
        puts "There were lexical errors:"
        scanner.errors.each { |err| puts "  #{err}" }
        return
      end

      puts tokens
    end
  end
end
