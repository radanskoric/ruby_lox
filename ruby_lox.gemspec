# frozen_string_literal: true

require_relative "lib/ruby_lox/version"

Gem::Specification.new do |spec|
  spec.name = "ruby_lox"
  spec.version = RubyLox::VERSION
  spec.authors = ["Radan Skorić"]
  spec.email = ["radan.skoric@gmail.com"]

  spec.summary = "Ruby implementation of the Lox language from the book \"Crafting Interpreters\""
  spec.description = <<~DESCRIPTION
    The first implementation of the educational Lox language in the book
    Crafting intepreters (https://craftinginterpreters.com) is done in Java.
    As an excercise, I'm doing it in Ruby instead.
  DESCRIPTION
  spec.homepage = "https://github.com/radanskoric/ruby_lox"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/radanskoric/ruby_lox"
  spec.metadata["changelog_uri"] = "https://github.com/radanskoric/ruby_lox/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
