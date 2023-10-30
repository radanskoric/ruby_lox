## Background

I finished the implementation entirely without RBS and Steep and then I decided to use it to learn RBS, which I haven't used before. Since the implementation was finished it was a nice little experiment to see how much will RBS and Steep help me in uncovering bugs. I did a reasonable effort to work on it as if it was production code, writting tests as I went. The main thing missing to make it like real work and which would have probably caught at least some of the bugs was that no one was reviewing my code.

## The bugs

I kept track of all the bugs that were found by RBS+Steep while adding it:

### With diagnostics set at Lenient

This didn't uncover any bugs.

### With regular diagnostics level

- `RubyLox::Resolver#visitVariable` was referencing `LoxCompilerError` instead of `LoxCompileError`, a typo. This was missed originally because I didn't write a test for an example where this error is raised (variable referencing itself in its own initializer). Notably, this bug was found before I added any type signatures.

- `RubyLox::Parser::ForStatement` had a place where it was referencing `expr::Literal` instead of `Expressions::Literal`. This was a bug caused by copy pasting form a place where `expr` was defined. I didn't have a test for this because it's kind of tricky to test. It's used to created a default for loop condition when it's missing. By the language spec the default condition is just `true` which makes it an infinite loop. Lox has no way to forcifully break out of a loop which means a clean test is impossible without modifying the language.

- **Not an error** but it did force me to do a minor improvement in `Intepreter#visitSuper`: When fetching "super" I am assuming I am getting back an instance of LoxClass which will be the case if there is no bug affecting that. However, if there was a bug and we got a different value back, it would blow up with a confusing error message. To satisfy it I added an explicit check with an informative error message which is also an improvement.
