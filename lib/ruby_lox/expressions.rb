# frozen_string_literal: true
# typed: true

require 'sorbet-runtime'

require_relative "ast_printer"

module RubyLox
  module Expressions
    Binary = Struct.new(:left, :operator, :right)
    Call = Struct.new(:callee, :paren, :arguments)
    Get = Struct.new(:object, :name)
    Grouping = Struct.new(:expression)
    Literal = Struct.new(:value)
    Logical = Struct.new(:left, :operator, :right)
    Set = Struct.new(:object, :name, :value)
    Super = Struct.new(:keyword, :method) # rubocop:disable Lint/StructNewOverride
    This = Struct.new(:keyword)
    Unary = Struct.new(:operator, :right)
    Variable = Struct.new(:name)
    Assign = Struct.new(:name, :value)

    [Binary, Call, Get, Grouping, Literal, Logical, Set,
     Super, This, Unary, Variable, Assign].each do |expression_class|
      klass_name = T.must(expression_class.name).split(":").last
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
