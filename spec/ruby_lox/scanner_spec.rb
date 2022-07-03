# frozen_string_literal: true
require "spec_helper"

RSpec.describe RubyLox::Scanner do
  subject(:scanner) { described_class.new(source) }

  describe "#scan_tokens" do
    subject(:tokens) { scanner.scan_tokens }
    let(:token_types) { tokens.map(&:type) }

    context "with only single character tokens" do
      let(:source) { "(){},.-+;*" }

      let(:expected) do
        %i[
          left_paren right_paren left_brace right_brace
          comma dot minus plus semicolon star
          eof
        ]
      end

      it "parses correctly" do
        expect(token_types).to eq expected
      end

      it "captures the source of the token" do
        expect(tokens.first.to_s).to eq "left_paren ( "
      end
    end

    context "with invalid characters" do
      let(:source) { "@(#\n^)" }

      before { scanner.scan_tokens }

      it "parses the valid tokens" do
        expect(token_types).to eq %i[left_paren right_paren eof]
      end

      it "marks the scanner as erronous" do
        expect(scanner).to be_error
      end

      it "logs the errors" do
        expect(scanner.errors.join("\n")).to eq <<~ERRORS.chomp
          Unexpected character "@" on line 1
          Unexpected character "#" on line 1
          Unexpected character "^" on line 2
        ERRORS
      end
    end

    context "with whitespace" do
      let(:source) { "  .\n  \t," }

      before { scanner.scan_tokens }

      it "parses the tokens" do
        expect(token_types).to eq %i[dot comma eof]
      end

      it "doesn't mark as erronous" do
        expect(scanner).not_to be_error
      end

      it "logs no errors" do
        expect(scanner.errors.join("\n")).to eq ""
      end
    end

    context "with ambiguous operators" do
      let(:source) { "! = < > != == <= >=" }

      it "parses the tokens" do
        expect(token_types).to eq %i[
          bang equal less greater
          bang_equal equal_equal less_equal greater_equal
          eof
        ]
      end

      it "correctly captures their strings" do
        expect(tokens.map { |t| t.to_s.split(" ")[1] }[..-2]).to eq %w[! = < > != == <= >=]
      end

      context "as last in the file" do
        let(:source) { "!" }

        it "parses the tokens" do
          expect(token_types).to eq %i[bang eof]
        end
      end
    end

    context "with a comment" do
      let(:source) { "\n#{comment}\n" }

      let(:comment) { "// This is a comment and has some operators: ! =" }

      it "skips the comment" do
        expect(token_types).to eq %i[eof]
      end

      context "as last in the file" do
        let(:source) { comment }

        it "skips the comment" do
          expect(token_types).to eq %i[eof]
        end
      end

      context "with a token after the comment" do
        let(:source) { "\n#{comment}\n(" }

        it "doesn't capture the comment in the token string" do
          expect(tokens.first.to_s).to eq "left_paren ( "
        end
      end
    end

    context "with a string" do
      let(:source) { "\"#{string}\"" }

      let(:string) { 'this is a string' }

      it "parses the tokens" do
        expect(token_types).to eq %i[string eof]
      end

      it "captures the string in the token with literal" do
        expect(tokens.first.to_s).to eq "string \"#{string}\" #{string}"
      end

      it "captures the correct literal" do
        expect(tokens.first.literal).to eq string
      end

      context "when it is multiline" do
        let(:string) { "this is a \n multiline \n string" }

        it "parses the tokens" do
          expect(token_types).to eq %i[string eof]
        end

        it "captures the string in the token with literal" do
          expect(tokens.first.to_s).to eq "string \"#{string}\" #{string}"
        end

        it "increments the line as it parses the string" do
          expect(tokens.last.line).to eq 3
        end
      end

      context "when the string is not closed" do
        let(:source) { "\"#{string}" }

        before { scanner.scan_tokens }

        it "marks the scanner as erronous" do
          expect(scanner).to be_error
        end

        it "logs the error" do
          expect(scanner.errors.join("\n")).to eq <<~ERRORS.chomp
            Expected string closing quote " but found none on line 1
          ERRORS
        end
      end
    end

    context "with an integer number" do
      let(:source) { "1234" }

      it "parses the tokens" do
        expect(token_types).to eq %i[number eof]
      end

      it "captures a number literal" do
        expect(tokens.first.literal).to eq 1234.0
      end

      context "followed by a single dot" do
        let(:source) { "1234." }

        it "parses the dot as separate token" do
          expect(token_types).to eq %i[number dot eof]
        end
      end
    end

    context "with a decimal number" do
      let(:source) { "1234.45" }

      it "parses the tokens" do
        expect(token_types).to eq %i[number eof]
      end

      it "captures a decimal number literal" do
        expect(tokens.first.literal).to eq 1234.45
      end
    end

    context "with an identifier" do
      let(:source) { " #{identifier} " }

      let(:identifier) { "ruby_lox" }

      it "parses the tokens" do
        expect(token_types).to eq %i[identifier eof]
      end

      it "captures the identifier name as literal" do
        expect(tokens.first.literal).to eq identifier
      end

      context "that contains numbers" do
        let(:identifier) { "foo42bar" }

        it "parses the tokens" do
          expect(token_types).to eq %i[identifier eof]
        end

        it "captures the identifier name as literal" do
          expect(tokens.first.literal).to eq identifier
        end
      end
    end

    context "with a reserved word" do
      let(:source) { "super class for fun" }

      it "parses as reserved word tokens" do
        expect(token_types).to eq %i[super class for fun eof]
      end
    end
  end
end
