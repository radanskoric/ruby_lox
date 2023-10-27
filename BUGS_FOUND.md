## Background

I initially did this project to learn about interpreters by following [Crafting Interpreters part II](https://craftinginterpreters.com/) using Ruby.

About the time when I finished I was also evaluating Ruby Gradual typing systems. I realised that this project is just the right size to learn by adding the typing systems to it fully. So I did that with both Sorbet and RBS. The results of these experiements are available on `sorbet` and `rbs` branches, respectively.

With both I also tracked how many new bugs were uncovered. When I was done I wondered what I would uncover by using the older approach of getting to 100% coverage (or very close) measured by Simplecov. This document tracks those results.

## The bugs

### Line coverage to 100%

I kept track of all the bugs that were found by getting to 100% test coverage (regular [simplecov](https://github.com/simplecov-ruby/simplecov) metric, i.e. line coverage):

- `RubyLox::Resolver#visitVariable` was referencing `LoxCompilerError` instead of `LoxCompileError`, a typo. This was missed originally because I didn't write a test for an example where this error is raised (variable referencing itself in its own initializer). This is the first uncovered line that SimpleCov pointed out to me.

- `RubyLox::AstPrinter` was not implementing methods for `This` and `Super` expressions. I discovered this because it first pointed out to me that `Get` is not covered so I wrote an example with objects and then when running that I discovered that the other two don't even have methods in the printer.

- `RubyLox::Parser#forStatement` was incorrectly handling an empty increment expression. It was checking for a semicolon when in fact the correct syntax for an empty increment is to just clsoe the for loop brackets with a right bracket. This was uncovered by adding a spec to cover the code handling an empty increment statement.

- *Not a bug* but while trying to cover with specs the error handling code in `Parser#parse` method I realised it will never run as it's covered by the more advanced error handling of same errors one method call down. This error handling was leftover from before the more advanced error handling with synchronization was added. So I just deleted the code.

### Branch coverage to 100%

- `RubyLox::Parser::ForStatement` had a place where it was referencing `expr::Literal` instead of `Expressions::Literal`. This was a bug caused by copy pasting form a place where `expr` was defined.

- *Not a bug* but the `Intepreter` had special code that would catch a return value which was redundant because we now have code in the `Resolver` that will raise a compile error if it encounters a return value in an initializer. So the code that is changing the return value of initializer is unreachable and I removed.
