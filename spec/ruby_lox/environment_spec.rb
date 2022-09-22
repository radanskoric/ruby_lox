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

  describe "#assign" do
    context "when variable has been defined" do
      before { env.define("foo", 10) }

      it "changes its value" do
        expect { env.assign("foo", 11) }.to change { env.get("foo") }.to(11)
      end
    end

    context "when variable has not been defined" do
      it "raises a runtime error" do
        expect { env.assign("foo", 11) }.to raise_error RubyLox::LoxRuntimeError, /Undefined variable 'foo'/
      end
    end
  end

  context "when an enclosing environment has been defined" do
    subject(:env) { described_class.new(enclosing) }

    let(:enclosing) { described_class.new }

    context "when enclosing environment defines the same variable as current one" do
      before do
        enclosing.define("foo", 11)
        env.define("foo", 12)
      end

      specify "#get returns current environment value" do
        expect(env.get("foo")).to eq 12
      end

      specify "#assign updates the current environment value" do
        env.assign("foo", 42)
        expect(env.get("foo")).to eq 42
        expect(enclosing.get("foo")).to eq 11
      end
    end

    context "when enclosing environment defines a variable that current doesn't" do
      before do
        enclosing.define("bar", 11)
      end

      specify "#get returns enclosing environment value" do
        expect(env.get("bar")).to eq 11
      end

      specify "#assign updates the enclosing environment value" do
        env.assign("bar", 42)
        expect(env.get("bar")).to eq 42
        expect(enclosing.get("bar")).to eq 42
      end
    end
  end
end
