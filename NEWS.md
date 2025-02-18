# cucumber 1.1.1

- ✨ Added option to set the indent of feature files. Useful when you use a different indent than the default 2 whitespaces. All user-facing options are documented in `?cucumber::opts`. (#5)
- ✨ Added validation of feature files to check if they have a consistent indentation. (#5)

# cucumber 1.1.0

- ✨ Added scenario `before` and `after` hooks.
- 📝 Added Behavior-Driven Development vignette.
- 🐛 Fix parsing error when there is a commented-out scenario after a step with a table.

# cucumber 1.0.4

- Added `test_interactive` parameter to `cucumber::test`. It allows you to interactively select which feature files to run. It can be useful to get quicker feedback when developing new features.

# cucumber 1.0.3

- Fixed float detection with multiple leading numbers, e.g. `11.1`, `+11.1`, `-11.1`.

# cucumber 1.0.2

- Fixed CRAN debian checks.

# cucumber 1.0.1

- ✨ Changed how `{string}` parameter is matched. It now matches on text in quotes. A step `Given I have a {string}` will match on `Given I have a "foo bar"`. This change brings the parser closer to how the original [cucumber expressions](https://github.com/cucumber/cucumber-expressions) work.
- ✨ Added a `{word}` parameter that matches on a single word. A step like `Given I have a {word}` will match on `Given I have a foo`.
- 🐛 Fix handling of repeated parameters in the same step. Now if there are steps `Given I have a {string} and a {string}` and `Given I have a {string}` it will match on `Given I have a "foo" and a "bar"` instead of throwing an error that multiple step definitions have been found.
- 📝 Improved documentation of parameters in `define_parameter_type` function docs.
- 📝 Added an example with snapshot test.


# cucumber 1.0.0

First stable version 🚀
