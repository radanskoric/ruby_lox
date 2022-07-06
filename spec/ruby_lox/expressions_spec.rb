# frozen_string_literal: true
require "spec_helper"

require "lib/ruby_lox/expressions"

RSpec.describe RubyLox::Expressions do
  describe "visitor pattern support" do
    class TestVisitor
      def visitBinary(binary)
        "visited Binary"
      end
    end

    let(:visitor) { TestVisitor.new }

    it "implements accept method" do
      expect(described_class::Binary.new("left", "operator", "right").accept(visitor)).to eq "visited Binary"
    end
  end
end
