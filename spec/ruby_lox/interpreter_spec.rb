# frozen_string_literal: true
require "spec_helper"

require "lib/ruby_lox/interpreter"
require "lib/ruby_lox/scanner"
require "lib/ruby_lox/parser"
require "lib/ruby_lox/expressions"
require "lib/ruby_lox/token"

RSpec.describe RubyLox::Interpreter do
  subject(:result) { ast.accept(interpreter) }

  let(:interpreter) { described_class.new }
  let(:ast) { RubyLox::Parser.new(tokens).parse }
  let(:tokens) { RubyLox::Scanner.new(source).scan_tokens }

  context "with parsed valid source" do
    context "with a calculation" do
      let(:source) { "-123 * (35.67 + 10)" }
      it { is_expected.to eq -5617.41 }
    end

    context "with a logical expression" do
      let(:source) { "!(42 > 13)" }
      it { is_expected.to eq false }
    end

    context "with a string concatenation" do
      let(:source) { '"foo" + "bar"' }
      it { is_expected.to eq "foobar" }
    end
  end

  context "with invalid source" do
    context "trying to negate a string" do
      let(:source) { '-"foo"' }

      it "raises a lox error" do
        expect { result }.to raise_error(described_class::LoxRuntimeError, /must be a number/)
      end
    end

    context "trying to divide strings" do
      let(:source) { '"foo" / "bar"' }

      it "raises a lox error" do
        expect { result }.to raise_error(described_class::LoxRuntimeError, /must be numbers/)
      end
    end

    context "trying to add a number and a string" do
      let(:source) { '4 + "foo"' }

      it "raises a lox error" do
        expect { result }.to raise_error(described_class::LoxRuntimeError, /must be two numbers or two strings/)
      end
    end
  end

  context "with an expression defined directly" do
    let(:ast) do # -123 * (35.67 + 10)
      expr::Binary.new(
        expr::Unary.new(
          RubyLox::Token.new(:minus, "-", nil, 1),
          expr::Literal.new(123)
        ),
        RubyLox::Token.new(:star, "*", nil, 1),
        expr::Grouping.new(
          expr::Binary.new(
            expr::Literal.new(35.67),
            RubyLox::Token.new(:plus, "+", nil, 1),
            expr::Literal.new(10),
          )
        )
      )
    end
    let(:expr) { RubyLox::Expressions }

    it "calculates the value of the ast" do
      expect(result).to eq -5617.41
    end
  end
end
