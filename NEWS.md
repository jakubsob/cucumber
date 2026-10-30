# cucumber 3.0.0

cucumber now follows more closely the Cucumber specification: feature files are parsed by a port of the [official Gherkin parser](https://github.com/cucumber/gherkin) and step descriptions are [Cucumber Expressions](https://github.com/cucumber/cucumber-expressions). Some feature files and step definitions that worked in 2.x need changes. The [migration guide](https://jakubsob.github.io/cucumber/articles/migration-to-3-0-0.html) describes every change in detail, with examples.

## Gherkin

- ⚠️ Feature files are parsed by a port of the official Gherkin parser. A line's meaning comes from its keyword, not its indentation, so the `cucumber.indent` option is removed. Some feature files that ran before fail to parse, and some steps get different text or arguments.
- ⚠️ Every feature file is parsed before anything runs. If one can't be parsed, no scenario runs and every parse error is reported with its file, line and column.
- ⚠️ Scenario Outline names have their placeholders replaced and no `(Example n)` suffix. Scenarios that share a name are numbered: `eating (1)`, `eating (2)`.
- ✨ The `Rule` keyword, the 80 languages of the official parser (`# language: fr`, or the `cucumber.language` option), and Markdown with Gherkin (`.feature.md` files).
- ✨ Outline placeholders are replaced in Doc Strings and Data Tables. A step can have both a Data Table and a Doc String, and a Doc String can have a media type, like `"""json`.

## Step definitions

- ⚠️ A step definition gets a Doc String as one string, with its media type in the `media_type` attribute. Set `options(cucumber.docstring_as_lines = TRUE)` to get a character vector of lines, as before.
- ⚠️ Text in step descriptions is matched literally, not as a regular expression. A description that starts with `^`, ends with `$` or is surrounded by `/` is a regular expression.
- ⚠️ A step that matches more than one step definition fails as ambiguous. Previously the first one was used.
- ⚠️ Invalid Cucumber Expressions are an error that points at the problem. A step definition that uses an undefined parameter type defines no step.
- ✨ The rest of the Cucumber Expressions syntax: optional text `cucumber(s)`, alternatives `Enter/Return` and the anonymous parameter `{}`.
- ✨ Code a step defers in its `context`, like `withr::local_options(.local_envir = context)`, runs when the scenario ends.
- ✨ A step's error shows its backtrace and names the feature file and line, like `Feature: basket.feature:3`.
- ⚠️ Snippets for undefined steps are generated like in Cucumber, with every matching parameter type, custom parameter types and `data_table` and `doc_string` arguments.

## Parameter types

- ⚠️ `{int}`, `{float}` and `{word}` match the same values as in Cucumber Expressions. `{byte}`, `{short}`, `{long}` and `{double}` are built in.
- ⚠️ A parameter type's `regexp` is used as is: replace `"\\\\d+"` with `"\\d+"`. Its capture groups are passed to the transformer as separate arguments.
- ⚠️ `define_parameter_type()` fails on a name that is already defined, an invalid name or an invalid regexp.
- ✨ `{string}` matches escaped quotes. `define_parameter_type()` accepts several regexps, `use_for_snippets` and `prefer_for_regexp_match`, and its `transformer` is optional.

## Running tests

- ⚠️ `test()` and `run()` find feature files in subdirectories of `path` too.
- ⚠️ Every step gets a result: passed, failed, pending, undefined, ambiguous or skipped. Pending, undefined and ambiguous steps fail their scenario and don't stop the run. Run with `strict = FALSE` to skip scenarios with pending or undefined steps instead.
- ⚠️ Tag expressions are parsed like the official [cucumber/tag-expressions](https://github.com/cucumber/tag-expressions): tags need their `@`, operators are lowercase, and `tags` must be one expression.
- ⚠️ `filter` must be one regular expression.
- ⚠️ Each feature file has a snapshot file of its own, like `_snaps/checkout-basket.feature.md`, whether run by `test()` or `run()`.
- ⚠️ cucumber needs testthat 3.3.2 or later.
- ✨ New `test()` and `run()` arguments: `dry_run`, `name`, `features` (with lines, like `"addition.feature:12"`), `fail_fast`, `retry` and `order`.
- ✨ `test()` runs feature files like `testthat::test_dir()` runs test files, without writing a test file into `path`. It reads its default `path` from the `cucumber.path` option, checks snapshots when `NOT_CRAN` isn't set, and its steps see the package's internal functions, like in `testthat::test_local()`.
- ✨ `run()` runs outside of a testthat run, like in the console.

## Hooks

- ⚠️ A hook's second argument is the scenario instead of its name. Replace `scenario_name` with `scenario$name`.
- ✨ Any number of `before()` and `after()` hooks, with `tags` and `name` arguments.
- ✨ `before_step()`, `after_step()`, `before_all()` and `after_all()` hooks.
- ✨ `skip_scenario()` skips a scenario from a `before()` hook or a step. `skip()` in a `before_all()` hook skips the whole run, and in an `after()` hook skips that hook.
- ✨ `context` and `scenario` print readably.

## Reporters

- ⚠️ Cucumber reporters are no longer testthat reporters, and testthat reporters can't be passed to `test()` or `run()`. A `CucumberReporter` gets the run as [Cucumber Messages](https://github.com/cucumber/messages) in `add_message()`. Its `start_feature()`, `end_feature()`, `start_step()` and `end_step()` methods are removed.
- ⚠️ The reporter that prints each step is renamed `CucumberPrettyReporter`. `CucumberProgressReporter`, the default, prints one line per feature. `show_praise` is deprecated.
- ⚠️ `run()` in a testthat run reports nothing of its own by default: testthat's reporter reports each scenario as a test, at its line of the feature file.
- ✨ New reporters, like Cucumber's formatters: `CucumberDotsReporter`, `CucumberProgressBarReporter`, `CucumberSummaryReporter`, `CucumberMessagesReporter`, `CucumberHtmlReporter`, `CucumberJunitReporter`, `CucumberRerunReporter`, `CucumberUsageReporter`, `CucumberSnippetsReporter` and `CucumberMultiReporter`.
- ✨ Reporters print or write to a file, and `report(file)` reports a run from its stored Cucumber Messages.
- ✨ `read_messages()` reads the Cucumber Messages of a run as tibbles.
- ✨ Steps and hooks attach data to the report with `context$attach()`, `context$log()` and `context$link()`.

## Documentation

- ✨ `features_rd()` puts scenarios of feature files in a function's help page.
- 📝 The migration guide and "How it works" show examples from the acceptance tests, as editor tabs with the files and the output of the run, like the Gherkin reference.
- 📝 New article: Get started, `vignette("get-started")`, from installing to a first run. The home page is shorter and puts the installation first; step matching syntax and parameter types moved to "How it works". The site's navigation is regrouped and the function reference groups reporters by what they do.
- 📝 "cucumber and testthat" starts with when to use which and how they complement each other.
- 📝 New articles: Reports, `vignette("reporting")`, and cucumber and testthat, `vignette("testthat")`.
- 📝 New help pages: `?cucumber`, linking every topic and article, and `?snapshots`. `?test` shows how feature files run like testthat test files, and what happens when they can't be parsed.

## Bug fixes

- 🐛 A failed expectation in a step fails the test run. Previously the scenario was reported as skipped.
- 🐛 A step or a hook fails when a `test_that()` test in it fails.
- 🐛 A scenario whose steps pass without an expectation is reported as passed, not skipped as an empty test.
- 🐛 testthat's reporters show a step's error as `Error: Step "<text>" failed` instead of its classes.
- 🐛 A step definition with the wrong number of arguments, or without `context` as its last argument, gets an error that shows the function to use.
- 🐛 An error of a parameter type's transformer names the parameter type.
- 🐛 A step's warnings are printed under the step, not above it.
- 🐛 `test()` passes its `...` to `grepl()` when matching `filter`, and errors on an unknown argument.
- 🐛 `test()`, `run()` and `features_rd()` check their arguments before anything runs, with an error that names the argument.
- 🐛 `test()` attaches cucumber, so setup files define steps without `cucumber::`.
- 🐛 `test()` keeps the step definitions, hooks and parameter types registered before it.
- 🐛 A `test_that()` test after `run()` in a test file is reported in the test file's context.

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
