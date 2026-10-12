# cucumber 3.0.0

cucumber now follows more closely the Cucumber specification: feature files are parsed by a port of the [official Gherkin parser](https://github.com/cucumber/gherkin) and step descriptions are [Cucumber Expressions](https://github.com/cucumber/cucumber-expressions). Some feature files and step definitions that worked in 2.x need changes. See the [migration guide](https://jakubsob.github.io/cucumber/articles/migration-to-3-0-0.html) for examples of each breaking change.

## Gherkin

- ⚠️ Feature files are parsed by a port of the official Gherkin parser. A line's meaning comes from its keyword, not its indentation, so the `cucumber.indent` option is removed. Some feature files that ran before fail to parse, and some steps get different text or arguments. Every parse error is reported with its line and column.
- ⚠️ Scenario Outline names are the outline name with placeholders replaced, without an `(Example n)` suffix. Scenarios that share a name are numbered in test results: `eating (1)`, `eating (2)`.
- ✨ Added support for the `Rule` keyword. A `Rule` groups scenarios that illustrate one business rule, can have its own `Background` (run after the `Feature`'s one) and passes its tags to its scenarios.
- ✨ Feature files can be written in any of the 80 languages of the official Gherkin parser, by starting them with a `# language:` line, e.g. `# language: fr` for `Fonctionnalité`, `Scénario`, `Soit`, `Quand` and `Alors`. Step definitions don't change.
- ✨ Scenario Outline placeholders are replaced in Doc Strings and Data Tables as well. Examples can have a description, and `Examples:` under a `Scenario:` makes it an outline.
- ✨ A step can have both a Data Table and a Doc String, and a Doc String can have a media type, like `"""json`.
- ✨ `Ability:` and `Business Need:` can be used instead of `Feature:`. Empty feature files and scenarios without steps no longer fail.

## Step definitions

- ⚠️ Text in step descriptions is matched literally. Previously it was treated as a regular expression, so characters like `.`, `?`, `*`, `|` or `[` could change what a step matched.
- ⚠️ A step that matches more than one step definition fails with an error listing every matching definition and where it is defined. Previously the first registered definition was silently used.
- ⚠️ Invalid Cucumber Expressions, like an empty optional `()`, an unescaped `/` in `"I visit /about"` or an undefined parameter type like `{colour}`, are an error that points at the problem.
- ⚠️ A step description that starts with `^`, ends with `$` or is surrounded by `/` is a regular expression. Each capture group's text is passed to the step, `NA` if the group didn't match. A group whose regexp is a parameter type's regexp, like `(\d+)` for `{int}`, is transformed by that parameter type.
- ✨ Step descriptions support the rest of the Cucumber Expressions syntax: optional text `cucumber(s)`, alternative words `Enter/Return`, and the anonymous parameter `{}`, which matches anything and passes it as text. Use `\\(`, `\\{` or `\\/` to match these characters literally. A backslash-escaped space keeps words together in an alternative: `"I live in New\\ York/Boston"`.

## Parameter types

- ⚠️ `{int}` matches `-?\d+`, so `+5` no longer matches. A value out of R's integer range fails the step instead of becoming `NA`.
- ⚠️ `{float}` matches integers like `12` and exponents like `1.5E3` too. It no longer matches any character in place of the decimal point. Defining both `{int}` and `{float}` variants of the same step makes integer steps ambiguous, so keep only the `{float}` one.
- ⚠️ `{word}` matches anything without whitespace, like `foo-bar` or `a.b`. Previously it matched only letters, digits and `_`.
- ⚠️ A parameter type's `regexp` is used as is. Previously it was a replacement string, so special characters needed four backslashes. Replace `"\\\\d+"` with `"\\d+"`.
- ⚠️ If a parameter type's `regexp` has capture groups, its transformer gets the text of each group as a separate argument. Use non-capturing groups, `(?:...)`, to keep the whole match.
- ✨ `{string}` matches strings with escaped quotes, like `"say \"hi\""`, and passes them unescaped: `say "hi"`.
- ✨ `define_parameter_type()` accepts several regexps and gets the `use_for_snippets` and `prefer_for_regexp_match` options.

## Running tests

- ⚠️ `test()` and `run()` find feature files in subdirectories of `path` too, like Cucumber's default `features/**/*.feature`. Previously only the files directly in `path` ran.
- ⚠️ Every step gets a result: passed, failed, pending, undefined, ambiguous or skipped. Steps after a step that didn't pass are reported as skipped.
- ⚠️ Undefined and ambiguous steps no longer stop the run. They fail their scenario, and the other scenarios still run, so every missing step's snippet is shown.
- ⚠️ `pending()` gives the step a `pending` status and fails the scenario. Previously the scenario was skipped. Run with `strict = FALSE` to skip scenarios with pending or undefined steps instead.
- ⚠️ Tag expressions are parsed like the official [cucumber/tag-expressions](https://github.com/cucumber/tag-expressions). A tag is everything up to whitespace or a parenthesis, so tags like `@team:payments` or `@and-more` can be used, and a backslash escapes a parenthesis: `"@wip\\(x\\)"`. Tags must be written with their `@`: `"smoke"` no longer matches `@smoke`. `and`, `or` and `not` must be lowercase. An invalid expression fails with the official error, e.g. `Tag expression "@a @b" could not be parsed because of syntax error: Expected operator.`
- ✨ `test()` and `run()` get a `dry_run` argument. A dry run matches every step to a step definition and reports undefined and ambiguous steps, but runs neither steps nor hooks. Like in cucumber-js, undefined and ambiguous steps don't fail a dry run: their scenarios are skipped.
- ✨ `test()` and `run()` get `name` and `features` arguments to run only some scenarios. `name = "^Adding"` runs scenarios whose name matches a regular expression. `features = "addition.feature:12"` runs the scenario at line 12 of a feature file, like `cucumber-js features/addition.feature:12`. The line of a Scenario Outline runs all its examples, the line of an example row runs only that example.
- ✨ `test()` and `run()` get a `fail_fast` argument. After the first failed scenario, the remaining scenarios are skipped and their hooks don't run, like `cucumber-js --fail-fast`. With `strict = TRUE`, a scenario with a pending or undefined step counts as failed.
- ✨ `test()` runs feature files from the directory set in the `cucumber.path` option when called without `path`, e.g. `options(cucumber.path = "features")`. It defaults to `"tests/acceptance"`, the previous default value.

## Hooks

- ⚠️ A hook's second argument is the scenario instead of its name: a list with its `name`, `tags` and `uri`, and in `after()` hooks its `status` and `error`. Replace `scenario_name` with `scenario$name`.
- ✨ Define any number of `before()` and `after()` hooks. Before hooks run in the order they are defined, after hooks in the reverse order. Previously a second hook of the same kind failed with "Hook already registered".
- ✨ `before_step()` and `after_step()` hooks run around each step. They get the step's `keyword` and `text`, and in `after_step()` its `status` and `error`. A failing step hook fails the step.
- ✨ `before_all()` and `after_all()` hooks run once before the first and after the last scenario of a run.
- ✨ Hooks get a `tags` argument, a tag expression. The hook runs only for scenarios that match it, e.g. `before(connect_db, tags = "@db")`.
- ✨ Hooks get a `name` argument. A named hook's errors start with its name, e.g. `Hook "Connect to the database" failed: connection refused`.
- ✨ A `before()` hook skips its scenario by calling `skip_scenario()`, like returning `'skipped'` in cucumber-js. The rest of the before hooks and the scenario's steps are skipped, and `after()` hooks get `"skipped"` as the scenario's `status`.
- ✨ A step can call `skip_scenario()` too, like returning `'skipped'` from a cucumber-js step. The step and the steps after it are skipped, the scenario is reported as skipped, and `after()` hooks still run.
- ✨ A failing `before()` hook reports the scenario's steps as skipped and fails the scenario.

## Reporters

- ⚠️ A step's `status` is `"failed"` for both failed expectations and errors. The `"error"` status is removed.
- ⚠️ A step keeps the keyword it's written with, so `step$keyword` can be `And`, `But` or `*`. The new `step$type` is `"Context"`, `"Action"`, `"Outcome"` or `"Unknown"`.
- ⚠️ `CucumberProgressReporter` prints the keyword as written and summarises the run like Cucumber, counting scenarios and steps by status, e.g. `2 scenarios (1 failed, 1 passed)`.

## Snippets

- ⚠️ Snippets for undefined steps are generated like cucumber-js: parameters in the order they appear in the step, one suggestion per matching parameter type, custom parameter types used, `data_table` and `doc_string` arguments, and repeated parameter names `string`, `string2`.
- 🐛 Snippets escape `(`, `{` and `/`, so the snippet matches the step it was generated for.
- 🐛 The snippet for a step starting with `And`, `But` or `*` uses `given()`, `when()` or `then()` from its type. Previously it suggested `step()`, which doesn't exist.

## Bug fixes

- 🐛 A scenario whose steps pass without calling any `expect_*()` function is reported as passed. Previously testthat reported it as skipped ("empty test"), e.g. in `JunitReporter` output.
- 🐛 `pending()` in a hook makes the scenario pending, like a pending step: it fails the run, or skips the scenario with `strict = FALSE`. In a `before_step()` or `after_step()` hook it makes the step pending. Previously `pending()` in a `before()` hook skipped the scenario, even in strict mode, and `after()` hooks didn't run.
- 🐛 `testthat::skip()` in a step or a `before()` hook skips the scenario like `skip_scenario()`. Previously `after()` hooks didn't run and the steps after it weren't reported. In other hooks it is an error, like `skip_scenario()`.
- 🐛 A step definition with the wrong number of arguments fails the step with an error that says how many arguments the step passes and the function to use, e.g. `Use \`function(int, data_table, context)\``. Previously it failed with `unused argument`. A step definition with `...` gets the step's arguments by position.
- 🐛 A failed expectation, like `expect_equal()`, in a step fails the test run. Previously testthat didn't record it, so the scenario was reported as skipped.
- 🐛 `test()` passes its `...` to `grepl()` when matching `filter`, as documented, e.g. `test(filter = "ADDITION", ignore.case = TRUE)`. Previously they were ignored.

# cucumber 2.2.0

- ✨ Added support for tags and tag expressions. Scenarios can now be tagged with `@tag` in feature files and filtered by passing `tags` to `cucumber::test()` or `cucumber::run()`. Feature-level tags are inherited by all scenarios in the feature.
- ✨ Added `pending()` function to mark steps as pending. A pending step will cause the scenario to be reported as skipped rather than failed. This is useful when writing the feature files before implementing the steps.
- ✨ Added step-level reporters. `CucumberReporter` is a base class (extending `testthat::Reporter`) with `start_feature()`/`end_feature()`/`start_step()`/`end_step()` hooks, and `CucumberProgressReporter` prints each step as it runs with its real `Given`/`When`/`Then` keyword. Pass one via the `reporter` argument to `cucumber::test()` or `cucumber::run()`.
- ✨ Missing step definitions now report a ready-to-paste snippet (with `{int}`/`{string}` placeholders inferred from the step text) instead of just an error.
- 🐛 Feature file normalisation now preserves the original `Given`/`When`/`Then` keyword (resolving `And`/`But`/`*` to the preceding one) instead of collapsing every step to a generic keyword.
- 🐛 Doc String content is now dedented relative to its opening delimiter, as the Gherkin specification requires. Previously a Doc String whose `"""` was indented less than the surrounding nesting lost the indentation of its own lines. [#16](https://github.com/jakubsob/cucumber/issues/16)

# cucumber 2.1.1

- 🐛 Fix normalisation of feature files. [#14](https://github.com/jakubsob/cucumber/pull/14)

# cucumber 2.1.0

- ✨ Added `cucumber::run()` function to allow running Cucumber tests alongside `testthat` tests.
- 🐛 Don't normalize feature files text within docstrings or tables.
- 🐛 Don't include docstrings and tables when validating feature files.
- 🧪 Added cucumber tests in `tests/acceptance`.

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
