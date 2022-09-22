# frozen_string_literal: true

require_relative "ast_printer"

module RubyLox
  module Expressions
    Binary = Struct.new(:left, :operator, :right)
    Unary = Struct.new(:operator, :right)
    Grouping = Struct.new(:expression)
    Literal = Struct.new(:value)
    Variable = Struct.new(:name)

    [Binary, Unary, Grouping, Literal, Variable].each do |expression_class|
      klass_name = expression_class.name.split(":").last
      expression_class.class_eval <<~RUBY
        def accept(visitor)
          visitor.visit#{klass_name}(self)
        end

        def inspect
          AstPrinter.new.visit#{klass_name}(self)
        end
      RUBY
    end
  end
end
