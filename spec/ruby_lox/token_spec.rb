# frozen_string_literal: true

require "spec_helper"

RSpec.describe RubyLox::Token do
  subject(:token) { described_class.new(type, lexeme, literal, line) }

  let(:type) { :number }
  let(:lexeme) { "42" }
  let(:literal) { 42 }
  let(:line) { 4 }

  describe "constructor" do
    context "when given an invalid type" do
      let(:type) { :something_completely_different }

      it "fails with an argument error" do
        expect { token }.to raise_error ArgumentError, /#{type}/
      end
    end
  end

  describe "#to_s" do
    subject(:str) { token.to_s }

    it "prints token information" do
      expect(str).to eq "number 42 42"
    end
  end

  describe "#==" do
    subject { token == other }

    context "when other is identical by type and literal" do
      let(:other) { described_class.new(type, nil, literal, nil) }

      it { is_expected.to eq(true) }
    end

    context "when other is different by type" do
      let(:other) { described_class.new(:string, lexeme, literal, line) }

      it { is_expected.to eq(false) }
    end

    context "when other is different by literal" do
      let(:other) { described_class.new(type, lexeme, 100, line) }

      it { is_expected.to eq(false) }
    end
  end

  describe "#hash" do
    subject { token.hash }

    context "when other is identical by type and literal" do
      let(:other) { described_class.new(type, nil, literal, nil) }

      it "matches" do
        expect(subject).to eq(other.hash)
      end
    end

    context "when other is different by type" do
      let(:other) { described_class.new(:string, lexeme, literal, line) }

      it "doesn't match" do
        expect(subject).not_to eq(other.hash)
      end
    end

    context "when other is different by literal" do
      let(:other) { described_class.new(type, lexeme, 100, line) }

      it "doesn't match" do
        expect(subject).not_to eq(other.hash)
      end
    end
  end
end
