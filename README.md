# RubyLox

The first implementation of the educational Lox language in the book
Crafting intepreters (https://craftinginterpreters.com) is done in Java.
As an excercise, I did it in **Ruby** instead.

While doing that I did my best to follow the naming and style convetions from
the book which is why the code sometimes looks a bit like Java, not Ruby. This
is for pragmatic reasons: to make it easier to find the relevant part in
the book when looking at the code.

The implementation is now complete, all of the language features from the
book are implemented.

## Usage

Clone the repo and install the gems with `bundle`.

After that you can use `bin/run` in 2 different ways:
- `bin/run` without arguments will run an interactive console that will evaluate Lox commands. Beware that you'll need to use `print` to see the output.
- `bin/run [script]` will run a lox script. There are several in examples folder, for example `bin/run examples/fibonacci.lox`

## Contributing

It's just a personal learning project, I expect no contributions.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
