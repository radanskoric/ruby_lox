# frozen_string_literal: true

require_relative "ast_printer"

module RubyLox
  module Statements
    Expression = Struct.new(:expression)
    Function = Struct.new(:name, :params, :body)
    Print = Struct.new(:expression)
    VarDecl = Struct.new(:name, :initializer)
    Block = Struct.new(:statements)
    If = Struct.new(:condition, :thenBranch, :elseBranch)
    While = Struct.new(:condition, :body)

    [Expression, Function, Print, VarDecl, Block, If, While].each do |statement_class|
      klass_name = statement_class.name.split(":").last
      statement_class.class_eval <<~RUBY
        def accept(visitor)
          visitor.visitStmt#{klass_name}(self)
        end

        def inspect
          AstPrinter.new.visitStmt#{klass_name}(self)
        end
      RUBY
    end
  end
end
