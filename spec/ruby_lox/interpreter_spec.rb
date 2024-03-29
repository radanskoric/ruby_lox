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

    context "with a calculation using division" do
      let(:source) { "print 42 / 7;" }
      it { is_expected.to eq "6" }
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

    context "with a complex logical expression" do
      let(:source) { "print (13 >= 13) and (100 < 101) and (1 <= 1) and (1 != 0);" }
      it { is_expected.to eq "true" }
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

    context "when declaring a variable without an initializer and assigning value later" do
      let(:source) { "var a; a = 42; print a;" }

      it "prints the value" do
        expect(output).to eq "42"
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

    context "when first argument of and logical operator is false" do
      let(:source) do
        <<~CODE
          fun isAnswer(num) {
            print num;
            return num == 42;
          }

          isAnswer(23) and isAnswer(42);
        CODE
      end

      it "shortcircuts the evaluation" do
        expect(output).to eq "23"
      end
    end

    context "with a while loop" do
      let(:source) { "var i = 3; while (i>0) { print i; i = i - 1; }" }

      it "runs the while loop" do
        expect(output).to eq "3\n2\n1"
      end
    end

    context "with a for loop" do
      let(:source) do
        <<~CODE
          for (
            var i = 3;
            i > 0;
            i = i - 1
          ) {
            print i;
          }
        CODE
      end

      it "runs the for loop" do
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

    context "when trying to print a function" do
      let(:source) do
        <<~CODE
          fun add5(a) { return a + 5; }
          print add5;
        CODE
      end

      it "works" do
        expect(output).to eq "<fn add5>"
      end
    end

    context "when trying to print a built in function" do
      let(:source) do
        <<~CODE
          print clock;
        CODE
      end

      it "works" do
        expect(output).to eq "<native fn clock>"
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

    context "when printing the class name" do
      let(:source) do
        <<~CODE
          class DevonshireCream {}
          print DevonshireCream; // Prints "DevonshireCream".
        CODE
      end

      it "works" do
        expect(output).to eq "DevonshireCream"
      end
    end

    context "when printing a class instance" do
      let(:source) do
        <<~CODE
          class DevonshireCream {}
          print DevonshireCream();
        CODE
      end

      it "works" do
        expect(output).to eq "DevonshireCream instance"
      end
    end

    context "when instance properties are set and accessed" do
      let(:source) do
        <<~CODE
          class Foo {}
          var level1 = Foo();
          var level2 = Foo();

          level2.value = "we have to go deeper";
          level1.nextlevel = level2;
          print level1.nextlevel.value;
        CODE
      end

      it "works" do
        expect(output).to eq "we have to go deeper"
      end
    end

    context "when instance methods are fetched and assigned" do
      let(:source) do
        <<~CODE
          class Person {
            sayName() {
              print this.name;
            }
          }

          var jane = Person();
          jane.name = "Jane";

          var bill = Person();
          bill.name = "Bill";

          bill.sayName = jane.sayName;
          bill.sayName();
        CODE
      end

      it "retains the reference to this" do
        expect(output).to eq "Jane"
      end
    end

    context "when a class has an init method" do
      let(:source) do
        <<~CODE
          class Greeting {
            init(salutation) {
              this.salutation = salutation;
            }

            greet(name) {
              print this.salutation + " " + name + "!";
            }
          }

          var warmGreeting = Greeting("Hello good friend");
          warmGreeting.greet("John");
        CODE
      end

      it "uses it to initialize the object" do
        expect(output).to eq "Hello good friend John!"
      end

      context "when the init method is called directly" do
        let(:source) do
          super() + <<~CODE
            print warmGreeting.init("Sup");
            warmGreeting.greet("Jane");
          CODE
        end

        it "re-inits the object and returns it" do
          expect(output).to eq <<~OUTPUT.chop
            Hello good friend John!
            Greeting instance
            Sup Jane!
          OUTPUT
        end
      end
    end

    context "when calling super from a method declared on parent class" do
      let(:source) do
        <<~CODE
          class A {
            method() {
              print "A method";
            }
          }

          class B < A {
            method() {
              print "B method";
            }

            test() {
              super.method();
            }
          }

          class C < B {}

          C().test();
        CODE
      end

      it "resolves super to the parent class from where the method was declared" do
        expect(output).to eq "A method"
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
      let(:source) { "clock(42);" }

      it "raises a lox error" do
        expect { result }.to raise_error(described_class::SemanticError, /0 arguments but got 1/)
      end
    end

    context "when trying to call a method on a non instance of a class" do
      let(:source) { "clock.tomorrow();" }

      it "raises a lox error" do
        expect { result }.to raise_error(described_class::SemanticError, /Only instances have properties/)
      end
    end

    context "when trying to set a value on a non instance of a class" do
      let(:source) { "clock.offset = 1;" }

      it "raises a lox error" do
        expect { result }.to raise_error(described_class::SemanticError, /Only instances have fields/)
      end
    end

    context "when redeclaring a variable in local scope" do
      let(:source) do
        <<~CODE
          fun bad() {
            var a = "first";
            var a = "second";
          }
        CODE
      end

      it "raises a lox error" do
        expect { result }.to raise_error(RubyLox::Resolver::Error, /Already a variable with this name in this scope/)
      end
    end

    context "when using the variable in its own initializer" do
      let(:source) do
        <<~CODE
          {
            var a = a;
          }
        CODE
      end

      it "raises a lox compile error" do
        expect { result }.to raise_error(RubyLox::LoxCompileError, /read local variable in its own initializer/)
      end
    end

    context "when returning from top level" do
      let(:source) { 'return "at top level";' }

      it "raises a lox error" do
        expect { result }.to raise_error(RubyLox::Resolver::Error, /Can't return from top-level code/)
      end
    end

    context "when accessing this outside a class" do
      let(:source) { "print this;" }

      it "raises a lox error" do
        expect { result }.to raise_error(RubyLox::Resolver::Error, /Can't use 'this' outside of a class/)
      end
    end

    context "when returning a value from an initializer" do
      let(:source) { "class Foo { init() { return 42; } }" }

      it "raises a lox error" do
        expect { result }.to raise_error(RubyLox::Resolver::Error, /Can't return a value from an initializer/)
      end
    end

    context "when inheriting from yourself" do
      let(:source) { "class Foo < Foo {}" }

      it "raises a lox error" do
        expect { result }.to raise_error(RubyLox::Resolver::Error, /A class can't inherit from itself/)
      end
    end

    context "when inheriting from something that's not a class" do
      let(:source) { "var Bar = 42;class Foo < Bar {}" }

      it "raises a lox error" do
        expect { result }.to raise_error(RubyLox::Interpreter::SemanticError, /Superclass must be a class/)
      end
    end

    context "when calling super from outside a class" do
      let(:source) { "super.notEvenInAClass();" }

      it "raises a lox error" do
        expect { result }.to raise_error(RubyLox::Resolver::Error, /Can't use 'super' outside of a class/)
      end
    end

    context "when calling super from a class without a superclass" do
      let(:source) do
        <<~CODE
          class Eclair {
            cook() {
              super.cook();
              print "Pipe full of crème pâtissière.";
            }
          }
        CODE
      end

      it "raises a lox error" do
        expect { result }.to raise_error(RubyLox::Resolver::Error, /Can't use 'super' in a class with no superclass/)
      end
    end

    context "when calling super but there's no super method" do
      let(:source) do
        <<~CODE
          class A {
          }

          class B < A {
            test() {
              super.test();
            }
          }

          B().test();
        CODE
      end

      it "raises a semantic error" do
        expect { result }.to raise_error(RubyLox::Interpreter::SemanticError, /Undefined property test/)
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
      expect(result).to eq(-5617.41)
    end
  end
end
