# frozen_string_literal: true

require "spec_helper"

RSpec.describe RubyLox::Runner do
  subject(:output) { runner.run(source); out.string.chop }

  let(:out) { StringIO.new }
  let(:runner) { described_class.new(out) }

  context "with valid source code" do
    let(:source) { "print 4 + 10;" }

    it "prints the result of calculation" do
      expect(output).to eq("14")
    end
  end

  context "with lexical errors" do
    let(:source) { "print 4 + 10&;" }

    it "prints the result of calculation" do
      expect(output).to include("Unexpected character \"&\" on line 1")
    end
  end

  context "with parser errors" do
    let(:source) { "print 4 + 10" }

    it "prints the result of calculation" do
      expect(output).to include("Expect ';' after expression")
    end
  end

  context "with resolver errors" do
    let(:source) { "{ var a = a; }" }

    it "prints the result of calculation" do
      expect(output).to include("Can't read local variable in its own initializer")
    end
  end

  context "with runtime errors" do
    let(:source) { "var a = \"test\"; a = a + 1;" }

    it "prints the result of calculation" do
      expect(output).to include("Runtime error")
    end
  end
end
