I'm keeping track of all the bugs that were found by Sorbet while adding it:

- `RubyLox::Resolver#visitVariable` was referencing `LoxCompilerError` instead of `LoxCompileError`, a typo. This was missed originally because I didn't write a test for an example where this error is raised (variable referencing itself in its own initializer). Notably, this bug was found before I added any type signatures.

