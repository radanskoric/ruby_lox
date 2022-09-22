# frozen_string_literal: true
require "spec_helper"

require "lib/ruby_lox/environment"

RSpec.describe RubyLox::Environment do
  subject(:env) { described_class.new }

  describe "#define" do
    it "accepts a value for a non existing variable" do
      expect(env.define("foo", 42)).to eq 42
    end

    it "accepts a value for an existing variable" do
      env.define("foo", 1)
      expect(env.define("foo", 2)).to eq 2
    end
  end

  describe "#get" do
    before { env.define("foo", 42) }

    it "returns the value if it has been defined" do
      expect(env.get("foo")).to eq 42
    end

    it "raises a runtime error if value has not been defined" do
      expect { env.get("bar") }.to raise_error RubyLox::LoxRuntimeError, /Undefined variable 'bar'/
    end
  end
end
