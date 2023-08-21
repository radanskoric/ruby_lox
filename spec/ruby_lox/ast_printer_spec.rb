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
end
