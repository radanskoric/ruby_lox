# frozen_string_literal: true
require "spec_helper"

require "lib/ruby_lox/parser"

RSpec.describe RubyLox::Parser do
  subject(:ast) { parser.parse }
  let(:parser) { described_class.new(tokens) }

  let(:expr) { RubyLox::Expressions }
  let(:stmt) { RubyLox::Statements }
  let(:token) { RubyLox::Token }

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
        token.new(:identifier, "foo", nil, 1),
        token.new(:equal_equal, "==", nil, 1),
        token.new(:identifier, "bar", nil, 1),
        token.new(:semicolon, ";", nil, 1),
      ]
    end

    it "returns a variable access expression" do
      expect(ast).to eq [stmt::Expression.new(
        expr::Binary.new(
          expr::Variable.new("foo"),
          token.new(:equal_equal, "==", nil, 1),
          expr::Variable.new("bar")
        )
      )]
    end

    it "is not erronous" do
      expect(parser).not_to be_error
    end
  end
end
