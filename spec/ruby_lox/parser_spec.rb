# frozen_string_literal: true
require "spec_helper"

require "lib/ruby_lox/parser"

RSpec.describe RubyLox::Parser do
  subject(:ast) { parser.parse }
  let(:parser) { described_class.new(tokens) }

  let(:expr) { RubyLox::Expressions }
  let(:token) { RubyLox::Token }

  before { ast }

  context "with a comparison of two numbers" do
    let(:tokens) do
      [
        token.new(:number, "13", 13, 1),
        token.new(:equal_equal, "==", nil, 1),
        token.new(:number, "4", 4, 1),
      ]
    end

    it "returns a binary comparison expression" do
      expect(ast).to eq expr::Binary.new(
        expr::Literal.new(13),
        token.new(:equal_equal, "==", nil, 1),
        expr::Literal.new(4)
      )
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
      ]
    end

    it "returns correct hierarchy of expressions" do
      expect(ast).to eq expr::Binary.new(
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
      ]
    end

    it "returns correct hierarchy of expressions" do
      expect(ast).to eq expr::Binary.new(
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

    it "returns nil" do
      expect(ast).to be_nil
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

    it "returns nil" do
      expect(ast).to be_nil
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
end
