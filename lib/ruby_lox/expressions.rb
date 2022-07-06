# frozen_string_literal: true

module RubyLox
  module Expressions
    Binary = Struct.new(:left, :operator, :right)
    Grouping = Struct.new(:expression)
    Literal = Struct.new(:value)
    Unary = Struct.new(:operator, :right)

    [Binary, Grouping, Literal, Unary].each do |expression_class|
      expression_class.class_eval <<~RUBY
        def accept(visitor)
          visitor.visit#{expression_class.name.split(":").last}(self)
        end
      RUBY
    end
  end
end
