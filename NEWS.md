# cucumber 2.0.1

- 🐛 Fix CRAN Debian checks.

# cucumber 2.0.0

See the [migration guide](https://jakubsob.github.io/cucumber/articles/migration-to-2-0-0.html).

- ✨ You can now run specifications directly with `cucumber::test()` function.

# cucumber 1.2.1

- 🐛 Fix hook registering that previously could only register one hook.

# cucumber 1.2.0

- ✨ Added support for "Scenario Outline", "Background" and "*" keywords.
- ⚠️ Keywords are not taken into account when looking for a step definition. See [Gherkin steps reference](https://cucumber.io/docs/gherkin/reference#steps).
- 🛡️ Added validation of feature files to fail early if malformed:
  - Checks for consistent indentation.
  - Check if a feature file has only one Feature.
- ✨ `after` hook runs even if a scenario fails. This is useful for cleaning up resources even if a test fails unexpectedly.
- ✨ Added option to set the indent of feature files. Useful when you use a different indent than the default 2 whitespaces. All user-facing options are documented in `?cucumber::opts`.
- 📝 Added "Gherkin Reference" article.

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
