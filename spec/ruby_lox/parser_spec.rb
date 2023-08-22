# frozen_string_literal: true

require "spec_helper"

require "lib/ruby_lox/parser"
require "lib/ruby_lox/scanner"

RSpec.describe RubyLox::Parser do
  subject(:ast) { parser.parse }
  let(:parser) { described_class.new(tokens) }

  let(:expr) { RubyLox::Expressions }
  let(:stmt) { RubyLox::Statements }
  let(:token) { RubyLox::Token }
  let(:tokens) { RubyLox::Scanner.new(source).scan_tokens }

  before { ast }

  context "with a comparison of two numbers" do
    let(:tokens) do
      [
        token.new(:number, "13", 13, 1),
        token.new(:equal_equal, "==", nil, 1),
        token.new(:number, "4", 4, 1),
        token.new(:semicolon, ";", nil, 1),
      ]
    end

    it "returns a binary comparison expression" do
      expect(ast).to eq [stmt::Expression.new(
        expr::Binary.new(
          expr::Literal.new(13),
          token.new(:equal_equal, "==", nil, 1),
          expr::Literal.new(4)
        )
      )]
    end

    it "is not erronous" do
      expect(parser).not_to be_error
    end
  end

  context "with operators of different precedence" do
    let(:tokens) do
      [
        token.new(:number, "13", 13, 1),
        token.new(:plus, "+", nil, 1),
        token.new(:number, "4", 4, 1),
        token.new(:star, "*", nil, 1),
        token.new(:minus, "-", nil, 1),
        token.new(:number, "2", 2, 1),
        token.new(:semicolon, ";", nil, 1),
      ]
    end

    it "returns correct hierarchy of expressions" do
      expect(ast).to eq [stmt::Expression.new(
        expr::Binary.new(
          expr::Literal.new(13),
          token.new(:plus, "+", nil, 1),
          expr::Binary.new(
            expr::Literal.new(4),
            token.new(:star, "*", nil, 1),
            expr::Unary.new(
              token.new(:minus, "-", nil, 1),
              expr::Literal.new(2)
            )
          )
        )
      )]
    end
  end

  context "with parentheses" do
    let(:tokens) do
      [
        token.new(:left_paren, "(", nil, 1),
        token.new(:number, "13", 13, 1),
        token.new(:plus, "+", nil, 1),
        token.new(:number, "4", 4, 1),
        token.new(:right_paren, ")", nil, 1),
        token.new(:star, "*", nil, 1),
        token.new(:number, "2", 2, 1),
        token.new(:semicolon, ";", nil, 1),
      ]
    end

    it "returns correct hierarchy of expressions" do
      expect(ast).to eq [stmt::Expression.new(
        expr::Binary.new(
          expr::Grouping.new(
            expr::Binary.new(
              expr::Literal.new(13),
              token.new(:plus, "+", nil, 1),
              expr::Literal.new(4),
            )
          ),
          token.new(:star, "*", nil, 1),
          expr::Literal.new(2),
        )
      )]
    end

    it "is not erronous" do
      expect(parser).not_to be_error
    end
  end

  context "with unclosed parentheses" do
    let(:tokens) do
      [
        token.new(:left_paren, "(", nil, 1),
        token.new(:number, "13", 13, 1),
        token.new(:plus, "+", nil, 1),
        token.new(:number, "4", 4, 2),
        token.new(:star, "*", nil, 2),
        token.new(:number, "2", 2, 2),
        token.new(:number, "3", 3, 3),
        token.new(:number, "4", 4, 4),
      ]
    end

    it "returns empty" do
      expect(ast).to be_empty
    end

    it "is erronous" do
      expect(parser).to be_error
    end

    it "reports a missing parentheses error" do
      expect(parser.errors.map(&:to_s)).to eq [
        "Error on line 3: Expect ')' after expression."
      ]
    end
  end

  context "starting with a token that can't start an expression" do
    let(:tokens) do
      [
        token.new(:number, "13", 13, 1),
        token.new(:plus, "+", nil, 1),
        token.new(:right_paren, ")", nil, 2),
      ]
    end

    it "returns empty" do
      expect(ast).to be_empty
    end

    it "is erronous" do
      expect(parser).to be_error
    end

    it "reports a bas expression start error" do
      expect(parser.errors.map(&:to_s)).to eq [
        "Error on line 2: Expect expression."
      ]
    end
  end

  context "with a print statement" do
    let(:tokens) do
      [
        token.new(:print, "print", nil, 1),
        token.new(:number, "4", 4, 1),
        token.new(:semicolon, ";", nil, 1),
      ]
    end

    it "returns correct hierarchy of expressions" do
      expect(ast).to eq [stmt::Print.new(
        expr::Literal.new(4),
      )]
    end
  end

  context "with a return statement" do
    let(:tokens) do
      [
        token.new(:return, "return", nil, 1),
        token.new(:number, "4", 4, 1),
        token.new(:semicolon, ";", nil, 1),
      ]
    end

    it "returns correct hierarchy of expressions" do
      expect(ast).to eq [stmt::Return.new(
        token.new(:return, "return", nil, 1),
        expr::Literal.new(4),
      )]
    end
  end

  context "with multiple statements" do
    let(:tokens) do
      [
        token.new(:print, "print", nil, 1),
        token.new(:number, "4", 4, 1),
        token.new(:semicolon, ";", nil, 1),
        token.new(:number, "13", 13, 1),
        token.new(:equal_equal, "==", nil, 1),
        token.new(:number, "4", 4, 1),
        token.new(:semicolon, ";", nil, 1),
      ]
    end

    it "returns a list of statements" do
      expect(ast).to eq [
        stmt::Print.new(
          expr::Literal.new(4),
        ),
        stmt::Expression.new(
          expr::Binary.new(
            expr::Literal.new(13),
            token.new(:equal_equal, "==", nil, 1),
            expr::Literal.new(4)
          )
        )
      ]
    end
  end

  context "with a variable declaration" do
    let(:tokens) do
      [
        token.new(:var, "var", nil, 1),
        token.new(:identifier, "foo", nil, 1),
        token.new(:equal, "=", nil, 1),
        token.new(:number, "4", 4, 1),
        token.new(:semicolon, ";", nil, 1),
      ]
    end

    it "returns variable declaration statement" do
      expect(ast).to eq [
        stmt::VarDecl.new(
          token.new(:identifier, "foo", nil, 1),
          expr::Literal.new(4)
        )
      ]
    end
  end

  context "with multiple broken variable declarations" do
    let(:tokens) do
      [
        token.new(:var, "var", nil, 1),
        token.new(:number, "13", 13, 1),
        token.new(:semicolon, ";", nil, 1),
        token.new(:var, "var", nil, 2),
        token.new(:identifier, "foo", nil, 2),
        token.new(:equal, "=", nil, 2),
        token.new(:equal, "=", 4, 2),
        token.new(:semicolon, ";", nil, 2),
      ]
    end

    it "returns empty" do
      expect(ast).to be_empty
    end

    it "is erronous" do
      expect(parser).to be_error
    end

    it "captures all errors" do
      expect(parser.errors.map(&:to_s)).to eq [
        "Error on line 1: Expect variable name.",
        "Error on line 2: Expect expression."
      ]
    end
  end

  context "with variable access" do
    let(:tokens) do
      [
        token.new(:identifier, "foo", "foo", 1),
        token.new(:equal_equal, "==", nil, 1),
        token.new(:identifier, "bar", "bar", 1),
        token.new(:semicolon, ";", nil, 1),
      ]
    end

    it "returns a variable access expression" do
      expect(ast).to eq [stmt::Expression.new(
        expr::Binary.new(
          expr::Variable.new(token.new(:identifier, "foo", "foo", 1)),
          token.new(:equal_equal, "==", nil, 1),
          expr::Variable.new(token.new(:identifier, "bar", "bar", 1))
        )
      )]
    end

    it "is not erronous" do
      expect(parser).not_to be_error
    end
  end

  context "with variable assignment" do
    let(:tokens) do
      [
        token.new(:identifier, "a", "a", 1),
        token.new(:equal, "=", nil, 1),
        token.new(:number, "4", 4, 1),
        token.new(:semicolon, ";", nil, 1),
      ]
    end

    it "returns an assignment expression" do
      expect(ast).to eq [stmt::Expression.new(
        expr::Assign.new(
          token.new(:identifier, "a", "a", 1),
          expr::Literal.new(4)
        )
      )]
    end

    it "is not erronous" do
      expect(parser).not_to be_error
    end
  end

  context "with invalid variable assignment" do
    let(:tokens) do
      [
        token.new(:string, "a", "a", 1),
        token.new(:equal, "=", nil, 1),
        token.new(:number, "4", 4, 1),
        token.new(:semicolon, ";", nil, 1),
      ]
    end

    it "returns empty" do
      expect(ast).to be_empty
    end

    it "produces invalid assignment error" do
      expect(parser).to be_error
      expect(parser.errors.map(&:to_s)).to eq [
        "Error on line 1: Invalid assignment target.",
      ]
    end
  end

  context "with a block" do
    let(:tokens) do
      [
        token.new(:left_brace, "{", nil, 1),
        token.new(:number, "4", 4, 1),
        token.new(:semicolon, ";", nil, 1),
        token.new(:right_brace, "}", nil, 1),
      ]
    end

    it "returns an block statement" do
      expect(ast).to eq [stmt::Block.new([
                                           stmt::Expression.new(
                                             expr::Literal.new(4)
                                           )
                                         ])]
    end
  end

  context "with an unclosed block" do
    let(:tokens) do
      [
        token.new(:left_brace, "{", nil, 1),
        token.new(:number, "4", 4, 1),
        token.new(:semicolon, ";", nil, 1),
      ]
    end

    it "produces invalid block error" do
      expect(parser).to be_error
      expect(parser.errors.map(&:to_s)).to eq [
        "Error on line 1: Expect '}' after block.",
      ]
    end
  end

  context "with an an if statement" do
    let(:tokens) do
      [
        token.new(:if, "if", nil, 1),
        token.new(:left_paren, "(", nil, 1),
        token.new(:true, "true", nil, 1),
        token.new(:right_paren, ")", nil, 1),
        token.new(:number, "42", 42, 2),
        token.new(:semicolon, ";", nil, 2),
      ]
    end

    context "without an else block" do
      it "produces an if statement without else branch" do
        expect(parser.errors).to eq []
        expect(ast).to eq [stmt::If.new(
          expr::Literal.new(true),
          stmt::Expression.new(expr::Literal.new(42)),
          nil
        )]
      end
    end

    context "with an else block" do
      let(:tokens) do
        super().concat([
                         token.new(:else, "else", nil, 3),
                         token.new(:number, "24", 24, 3),
                         token.new(:semicolon, ";", nil, 3),
                       ])
      end

      it "produces an if statement with an else branch" do
        expect(parser.errors).to eq []
        expect(ast).to eq [stmt::If.new(
          expr::Literal.new(true),
          stmt::Expression.new(expr::Literal.new(42)),
          stmt::Expression.new(expr::Literal.new(24))
        )]
      end
    end
  end

  context "with a logical or statement" do
    let(:tokens) do
      [
        token.new(:true, "true", nil, 1),
        token.new(:or, "or", nil, 1),
        token.new(:false, "false", nil, 1),
        token.new(:semicolon, ";", nil, 1),
      ]
    end

    it "produces an logical or statement" do
      expect(parser.errors).to eq []
      expect(ast).to eq [stmt::Expression.new(
        expr::Logical.new(
          expr::Literal.new(true),
          token.new(:or, "or", nil, 1),
          expr::Literal.new(false)
        )
      )]
    end
  end

  context "with a logical and statement" do
    let(:tokens) do
      [
        token.new(:false, "false", nil, 1),
        token.new(:and, "and", nil, 1),
        token.new(:true, "true", nil, 1),
        token.new(:semicolon, ";", nil, 1),
      ]
    end

    it "produces an logical or statement" do
      expect(parser.errors).to eq []
      expect(ast).to eq [stmt::Expression.new(
        expr::Logical.new(
          expr::Literal.new(false),
          token.new(:and, "and", nil, 1),
          expr::Literal.new(true)
        )
      )]
    end
  end

  context "with a while statement" do
    let(:tokens) do
      [
        token.new(:while, "while", nil, 1),
        token.new(:left_paren, "(", nil, 1),
        token.new(:true, "true", nil, 1),
        token.new(:right_paren, ")", nil, 1),
        token.new(:number, "4", 4, 1),
        token.new(:semicolon, ";", nil, 1),
      ]
    end

    it "produces a while statement" do
      expect(parser.errors).to eq []
      expect(ast).to eq [stmt::While.new(
        expr::Literal.new(true),
        stmt::Expression.new(
          expr::Literal.new(4)
        )
      )]
    end
  end

  context "with a for loop" do
    let(:source) { "for (var i = 0; i < 10; i = i + 1) print i;" }

    let(:expected) do
      RubyLox::Parser.new(
        RubyLox::Scanner.new(
          <<~CODE
            {
              var i = 0;
              while (i < 10) {
                print i;
                i = i + 1;
              }
            }
          CODE
        ).scan_tokens
      ).parse
    end

    it "desugars it to a while loop" do
      expect(parser.errors).to eq []
      expect(ast).to eq expected
    end
  end

  context "with a function call" do
    let(:source) { "average(1, 2);" }

    it "produces a function call" do
      expect(parser.errors).to eq []
      expect(ast).to eq [stmt::Expression.new(
        expr::Call.new(
          expr::Variable.new(token.new(:identifier, "average", "average", 1)),
          token.new(:right_paren, ")", nil, 1),
          [
            expr::Literal.new(1),
            expr::Literal.new(2)
          ]
        )
      )]
    end

    context "with no arguments" do
      let(:source) { "average();" }

      it "produces a function call with no arguments" do
        expect(parser.errors).to eq []
        expect(ast).to eq [stmt::Expression.new(
          expr::Call.new(
            expr::Variable.new(token.new(:identifier, "average", "average", 1)),
            token.new(:right_paren, ")", nil, 1),
            []
          )
        )]
      end
    end

    context "with more than 255 arguments" do
      let(:source) { "average(#{(256.times.to_a.join("\n,"))});" }

      it "logs an error" do
        expect(parser.errors.map(&:to_s)).to eq [
          "Error on line 256: Can't have more than 255 arguments.",
        ]
      end
    end
  end

  context "with a function declaration" do
    let(:source) { "fun add(a, b) { a + b; }" }

    let(:expected) do
      [
        stmt::Function.new(
          token.new(:identifier, "add", "add", 1),
          [
            token.new(:identifier, "a", "a", 1),
            token.new(:identifier, "b", "b", 1),
          ],
          stmt::Block.new([
                            stmt::Expression.new(
                              expr::Binary.new(
                                expr::Variable.new(token.new(:identifier, "a", "a", 1)),
                                token.new(:plus, "+", nil, 1),
                                expr::Variable.new(token.new(:identifier, "b", "b", 1))
                              )
                            )
                          ])
        )
      ]
    end

    it "produces a function call" do
      expect(parser.errors).to eq []
      expect(ast).to eq expected
    end
  end

  context "with a class declaration" do
    let(:source) do
      <<~CODE
        class Foo {
          bar(test) {
            print test;
          }
        }
      CODE
    end

    let(:expected) do
      [
        stmt::Class.new(
          token.new(:identifier, "Foo", "Foo", 1),
          nil,
          [
            stmt::Function.new(
              token.new(:identifier, "bar", "bar", 2),
              [
                token.new(:identifier, "test", "test", 2)
              ],
              stmt::Block.new(
                [
                  stmt::Print.new(
                    expr::Variable.new(token.new(:identifier, "test", "test", 3))
                  )
                ]
              )
            )
          ]
        )
      ]
    end

    it "produces a class declaration" do
      expect(parser.errors).to eq []
      expect(ast).to eq expected
    end
  end

  context "with a class that has a superclass" do
    let(:source) { "class Foo < Bar {}" }

    let(:expected) do
      [
        stmt::Class.new(
          token.new(:identifier, "Foo", "Foo", 1),
          expr::Variable.new(token.new(:identifier, "Bar", "Bar", 1)),
          []
        )
      ]
    end

    it "produces a class declaration" do
      expect(parser.errors).to eq []
      expect(ast).to eq expected
    end
  end
end
