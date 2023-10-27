# frozen_string_literal: true

require "spec_helper"

require "lib/ruby_lox/ast_printer"
require "lib/ruby_lox/expressions"
require "lib/ruby_lox/token"

RSpec.describe RubyLox::AstPrinter do
  let(:printer) { described_class.new }

  let(:ast) do
    expr::Binary.new(
      expr::Unary.new(
        RubyLox::Token.new(:minus, "-", nil, 1),
        expr::Literal.new(123)
      ),
      RubyLox::Token.new(:star, "*", nil, 1),
      expr::Grouping.new(
        expr::Literal.new(45.67)
      )
    )
  end
  let(:expr) { RubyLox::Expressions }

  it "prints the ast in prefix notation" do
    expect(ast.accept(printer)).to eq "(* (- 123) (group 45.67))"
  end

  context "when tested starting with source code" do
    let(:ast) { RubyLox::Parser.new(tokens).parse }
    let(:tokens) { RubyLox::Scanner.new(source).scan_tokens }

    context "with function calls printing" do
      let(:source) do
        <<~CODE
          fun greet(name) {
            print "Hi there, " + name + "!";
          }

          var new_user = "Bob";
          greet(new_user);
        CODE
      end

      it "prints the ast in prefix notation" do
        expect(printer.print(ast)).to eq <<~PREFIX.chop
          (fun greet(name) { (print (+ (+ Hi there,  identifier name name) !)) })
          (var new_user Bob)
          (expr (call identifier greet greet (identifier new_user new_user)))
        PREFIX
      end
    end

    context "with branching and function calls returning values" do
      let(:source) do
        <<~CODE
          fun check() {
            return true;
          }

          var a;
          if (check()) {
            a = 5;
          } else {
            a = 10;
          };

          if (a > 6 and a < 20) {
            print "OK!";
          };
        CODE
      end

      it "prints the ast in prefix notation" do
        expect(printer.print(ast)).to eq <<~PREFIX.chop
          (fun check() { (return true) })
          (var a)
          (if (call identifier check check ()) { (expr (= identifier a a 5.0)) } { (expr (= identifier a a 10.0)) })
          (if (and (> identifier a a 6.0) (< identifier a a 20.0)) { (print OK!) })
        PREFIX
      end
    end

    context "with classes" do
      let(:source) do
        <<~CODE
          class Person {
            init(name) {
              this.name = name;
            }

            greet() {
              print "Hi there, " + this.name + "!";
            }
          }

          class Customer < Person {
            greet() {
              super.greet();
              print "What are you looking for today?";
            }
          }

          var new_customer = new Customer("Jane");
          new_customer.greet();
        CODE
      end

      it "prints the ast in prefix notation" do
        expect(printer.print(ast)).to eq <<~PREFIX.chop
          (class Person (fun init(name) { (expr (set this name identifier name name)) }),(fun greet() { (print (+ (+ Hi there,  (get this name)) !)) }))
          (class Customer (fun greet() { (expr (call super.greet ())),(print What are you looking for today?) }))
          (expr (call (get identifier new_customer new_customer greet) ()))
        PREFIX
      end
    end

    context "with a while loop" do
      let(:source) do
        <<~CODE
          while (true) {
            print "Still true";
          }
        CODE
      end

      it "prints the ast in prefix notation" do
        expect(printer.print(ast)).to eq <<~PREFIX.chop
          (while true { (print Still true) })
        PREFIX
      end
    end

    context "when returning without a value" do
      let(:source) do
        <<~CODE
          fun test() {
            return;
          }
        CODE
      end

      it "prints the ast in prefix notation" do
        expect(printer.print(ast)).to eq <<~PREFIX.chop
          (fun test() { (return ) })
        PREFIX
      end
    end
  end
end
