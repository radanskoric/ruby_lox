# frozen_string_literal: true
require "spec_helper"

require "stringio"

require "lib/ruby_lox/interpreter"
require "lib/ruby_lox/scanner"
require "lib/ruby_lox/parser"
require "lib/ruby_lox/expressions"
require "lib/ruby_lox/token"

RSpec.describe RubyLox::Interpreter do
  subject(:result) { interpreter.interpret(ast) }

  let(:interpreter) { described_class.new(out) }
  let(:out) { StringIO.new }
  let(:ast) { RubyLox::Parser.new(tokens).parse }
  let(:tokens) { RubyLox::Scanner.new(source).scan_tokens }

  context "with parsed valid source" do
    subject(:output) { result; out.string.chop }

    context "with a calculation" do
      let(:source) { "print -123 * (35.67 + 10);" }
      it { is_expected.to eq "-5617.41" }
    end

    context "with a calculation returning integer" do
      let(:source) { "print 4 + 10;" }
      it "prints just the whole number" do
        expect(output).to eq "14"
      end
    end

    context "with a logical expression" do
      let(:source) { "print !(42 > 13);" }
      it { is_expected.to eq "false" }
    end

    context "with a string concatenation" do
      let(:source) { 'print "foo" + "bar";' }
      it { is_expected.to eq "foobar" }
    end

    context "with global variables declaration" do
      let(:source) do
        <<~CODE
          var a = 1;
          var b = 2;
          print a + b;
        CODE
      end

      it "evaluates and uses values of variables" do
        expect(output).to eq "3"
      end
    end

    context "with global variables assignment" do
      let(:source) do
        <<~CODE
          var a = 1;
          a = 2;
          print a;
        CODE
      end

      it "updates the variable value" do
        expect(output).to eq "2"
      end
    end

    context "with variables in blocks" do
      let(:source) do
        <<~CODE
          var a = 1;
          {
            var a = 2;
            print a;
          }
          print a;
        CODE
      end

      it "implements scoping and shadowing " do
        expect(output).to eq "2\n1"
      end
    end

    context "with an if statement" do
      let(:source) { "if (#{condition}) print \"yes\"; else print \"no\";" }

      context "that has a true condition" do
        let(:condition) { "2+2 == 4" }

        it "executes the then branch" do
          expect(output).to eq "yes"
        end
      end

      context "that has a false condition" do
        let(:condition) { "2+2 == 4+4" }

        it "executes the then branch" do
          expect(output).to eq "no"
        end
      end
    end

    context "with a logical expression" do
      let(:source) { "print false or true and 42 or 13;" }

      it "evaluates it in correct order" do
        expect(output).to eq "42"
      end
    end

    context "with a while loop" do
      let(:source) { "var i = 3; while (i>0) { print i; i = i - 1; }" }

      it "runs the while loop" do
        expect(output).to eq "3\n2\n1"
      end
    end
  end

  context "with invalid source" do
    context "trying to negate a string" do
      let(:source) { '-"foo";' }

      it "raises a lox error" do
        expect { result }.to raise_error(described_class::SemanticError, /must be a number/)
      end
    end

    context "trying to divide strings" do
      let(:source) { '"foo" / "bar";' }

      it "raises a lox error" do
        expect { result }.to raise_error(described_class::SemanticError, /must be numbers/)
      end
    end

    context "trying to add a number and a string" do
      let(:source) { '4 + "foo";' }

      it "raises a lox error" do
        expect { result }.to raise_error(described_class::SemanticError, /must be two numbers or two strings/)
      end
    end
  end

  context "with an expression defined directly" do
    subject(:result) { ast.accept(interpreter) }

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
