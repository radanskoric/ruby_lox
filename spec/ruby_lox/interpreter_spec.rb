# frozen_string_literal: true
require "spec_helper"

require "stringio"

require "lib/ruby_lox/interpreter"
require "lib/ruby_lox/scanner"
require "lib/ruby_lox/parser"
require "lib/ruby_lox/expressions"
require "lib/ruby_lox/token"

RSpec.describe RubyLox::Interpreter do
  subject(:result) do
    RubyLox::Resolver.new(interpreter).resolve(ast)
    interpreter.interpret(ast)
  end

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

        it "executes the else branch" do
          expect(output).to eq "no"
        end
      end

      context "when there is no else branch" do
        let(:source) { "if (#{condition}) print \"yes\";" }

        context "that has a true condition" do
          let(:condition) { "2+2 == 4" }

          it "executes the then branch" do
            expect(output).to eq "yes"
          end
        end

        context "that has a false condition" do
          let(:condition) { "2+2 == 4+4" }

          it "does nothing" do
            expect(output).to eq ""
          end
        end
      end

      context "when there are no branches" do
        let(:source) { "if (true) ;" }

        it "does nothing" do
          expect(output).to eq ""
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

    context "with a native function call" do
      let(:source) { "print clock();" }

      it "works" do
        expect(output).not_to be_empty
      end
    end

    context "with a custom function that does not return a value" do
      let(:source) do
        <<~CODE
          fun print_with_title(title, output) {
            print title;
            print output;
            return;
          }

          print_with_title("Answer:", 42);
        CODE
      end

      it "works" do
        expect(output).to eq "Answer:\n42"
      end
    end

    context "with a custom function that returns a value" do
      let(:source) do
        <<~CODE
          fun add5(a) {
            return a + 5;
          }

          print add5(37);
        CODE
      end

      it "works" do
        expect(output).to eq "42"
      end
    end

    context "with a variable name rebound after closure creation" do
      let(:source) do
        <<~CODE
          var a = "global";
          {
            fun showA() {
              print a;
            }

            showA();
            var a = "block";
            showA();
          }
        CODE
      end

      it "keeps the closure bound to original definition" do
        expect(output).to eq "global\nglobal"
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

    context "when trying to call a non function" do
      let(:source) { '"totally not a function"();' }

      it "raises a lox error" do
        expect { result }.to raise_error(described_class::SemanticError, /only call functions and classes/)
      end
    end

    context "when calling a function with wrong arity" do
      let(:source) { 'clock(42);' }

      it "raises a lox error" do
        expect { result }.to raise_error(described_class::SemanticError, /0 arguments but got 1/)
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
