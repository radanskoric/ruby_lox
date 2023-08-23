## Background

I finished the implementation entirely without Sorbet and then I decided to use it to learn Sorbet, which I haven't used before. Since the implementation was finished it was a nice little experiment to see how much will Sorbet help me in uncovering bugs. I did a reasonable effort to work on it as if it was production code, writting tests as I went. The main thing missing to make it like real work and which would have probably caught at least some of the bugs was that no one was reviewing my code.

## The bugs

I kept track of all the bugs that were found by Sorbet while adding it:

### Out of the box, i.e. running it just as if all files are `typed: false`, just basic checks

- `RubyLox::Resolver#visitVariable` was referencing `LoxCompilerError` instead of `LoxCompileError`, a typo. This was missed originally because I didn't write a test for an example where this error is raised (variable referencing itself in its own initializer). Notably, this bug was found before I added any type signatures.

### Adding `typed: true` to all files

- `RubyLox::Parser::ForStatement` had a place where it was referencing `expr::Literal` instead of `Expressions::Literal`. This was a bug caused by copy pasting form a place where `expr` was defined. I didn't have a test for this because it's kind of tricky to test. It's used to created a default for loop condition when it's missing. By the language spec the default condition is just `true` which makes it an infinite loop. Lox has no way to forcifully break out of a loop which means a clean test is impossible without modifying the language.

