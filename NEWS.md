# cucumber 3.0.0

cucumber now follows more closely the Cucumber specification: feature files are parsed by a port of the [official Gherkin parser](https://github.com/cucumber/gherkin) and step descriptions are [Cucumber Expressions](https://github.com/cucumber/cucumber-expressions). Some feature files and step definitions that worked in 2.x need changes. See the [migration guide](https://jakubsob.github.io/cucumber/articles/migration-to-3-0-0.html) for examples of each breaking change.

## Gherkin

- ⚠️ Feature files are parsed by a port of the official Gherkin parser. A line's meaning comes from its keyword, not its indentation, so the `cucumber.indent` option is removed. Some feature files that ran before fail to parse, and some steps get different text or arguments. Every parse error is reported with its line and column.
- ⚠️ Every feature file is parsed before anything runs. If any file can't be parsed, no scenario runs and the parse errors of every file are reported, each as `Parse error in "<file>" (line:column): ...`. Previously the files before the broken one ran and the files after it were skipped.
- ⚠️ Scenario Outline names are the outline name with placeholders replaced, without an `(Example n)` suffix. Scenarios that share a name are numbered in test results: `eating (1)`, `eating (2)`.
- ✨ Added support for the `Rule` keyword. A `Rule` groups scenarios that illustrate one business rule, can have its own `Background` (run after the `Feature`'s one) and passes its tags to its scenarios.
- ✨ Feature files can be written in any of the 80 languages of the official Gherkin parser, by starting them with a `# language:` line, e.g. `# language: fr` for `Fonctionnalité`, `Scénario`, `Soit`, `Quand` and `Alors`. Step definitions don't change.
- ✨ Scenario Outline placeholders are replaced in Doc Strings and Data Tables as well. Examples can have a description, and `Examples:` under a `Scenario:` makes it an outline.
- ✨ A step can have both a Data Table and a Doc String, and a Doc String can have a media type, like `"""json`.
- ✨ `Ability:` and `Business Need:` can be used instead of `Feature:`. Empty feature files and scenarios without steps no longer fail.

## Step definitions

- ⚠️ A step definition gets a Doc String as one string, with its lines joined by `"\n"`, like Cucumber does. Previously it got a character vector of lines. The Doc String's media type, like `json` for `"""json`, is in its `media_type` attribute. Set `options(cucumber.docstring_as_lines = TRUE)` to keep getting a character vector of lines.
- ⚠️ Text in step descriptions is matched literally. Previously it was treated as a regular expression, so characters like `.`, `?`, `*`, `|` or `[` could change what a step matched.
- ⚠️ A step that matches more than one step definition fails with an error listing every matching definition and where it is defined. Previously the first registered definition was silently used.
- ⚠️ Invalid Cucumber Expressions, like an empty optional `()` or an unescaped `/` in `"I visit /about"`, are an error that points at the problem.
- ⚠️ A step definition that uses an undefined parameter type, like `{colour}`, defines no step. The run goes on, the steps it would match are undefined, and the summary lists the undefined parameter types.
- ⚠️ A step description that starts with `^`, ends with `$` or is surrounded by `/` is a regular expression. Each capture group's text is passed to the step, `NA` if the group didn't match. A group whose regexp is a parameter type's regexp, like `(\d+)` for `{int}`, is transformed by that parameter type. An invalid regular expression is an error that shows it.
- ✨ Step descriptions support the rest of the Cucumber Expressions syntax: optional text `cucumber(s)`, alternative words `Enter/Return`, and the anonymous parameter `{}`, which matches anything and passes it as text. Use `\\(`, `\\{` or `\\/` to match these characters literally. A backslash-escaped space keeps words together in an alternative: `"I live in New\\ York/Boston"`.

## Parameter types

- ⚠️ `{int}` matches `-?\d+`, so `+5` no longer matches. A value out of R's integer range fails the step instead of becoming `NA`.
- ⚠️ `{float}` matches integers like `12` and exponents like `1.5E3` too. It no longer matches any character in place of the decimal point. Defining both `{int}` and `{float}` variants of the same step makes integer steps ambiguous, so keep only the `{float}` one.
- ⚠️ `{word}` matches anything without whitespace, like `foo-bar` or `a.b`. Previously it matched only letters, digits and `_`.
- ⚠️ A parameter type's `regexp` is used as is. Previously it was a replacement string, so special characters needed four backslashes. Replace `"\\\\d+"` with `"\\d+"`.
- ⚠️ If a parameter type's `regexp` has capture groups, its transformer gets the text of each group as a separate argument. Use non-capturing groups, `(?:...)`, to keep the whole match.
- ⚠️ `define_parameter_type()` fails on a name that is already defined, like `int`, or that contains `{`, `}`, `(`, `)`, `\` or `/`, and on a second type with `prefer_for_regexp_match = TRUE` for the same regexp, like cucumber-expressions. Previously a second definition silently replaced the first.
- ✨ `{string}` matches strings with escaped quotes, like `"say \"hi\""`, and passes them unescaped: `say "hi"`.
- ✨ `define_parameter_type()` accepts several regexps and gets the `use_for_snippets` and `prefer_for_regexp_match` options.

## Running tests

- ⚠️ `test()` and `run()` find feature files in subdirectories of `path` too, like Cucumber's default `features/**/*.feature`. Previously only the files directly in `path` ran. Symbolic links to feature files are run too.
- ⚠️ Every step gets a result: passed, failed, pending, undefined, ambiguous or skipped. Steps after a step that didn't pass are reported as skipped.
- ⚠️ Undefined and ambiguous steps no longer stop the run. They fail their scenario, and the other scenarios still run, so every missing step's snippet is shown.
- ⚠️ Undefined and ambiguous steps after a step or a `before()` hook that skipped the scenario are skipped, so they no longer fail it.
- ⚠️ `pending()` gives the step a `pending` status and fails the scenario. Previously the scenario was skipped. Run with `strict = FALSE` to skip scenarios with pending or undefined steps instead.
- ⚠️ Tag expressions are parsed like the official [cucumber/tag-expressions](https://github.com/cucumber/tag-expressions). A tag is everything up to whitespace or a parenthesis, so tags like `@team:payments` or `@and-more` can be used, and a backslash escapes a parenthesis: `"@wip\\(x\\)"`. Tags must be written with their `@`: `"smoke"` no longer matches `@smoke`. `and`, `or` and `not` must be lowercase. An invalid expression fails with the official error, e.g. `Tag expression "@a @b" could not be parsed because of syntax error: Expected operator.`
- ✨ `test()` and `run()` get a `dry_run` argument. A dry run matches every step to a step definition and reports undefined and ambiguous steps, but runs neither steps nor hooks. Undefined and ambiguous steps don't fail a dry run: their scenarios are skipped.
- ✨ `test()` and `run()` get `name` and `features` arguments to run only some scenarios. `name = "^Adding"` runs scenarios whose name matches a regular expression. `features = "addition.feature:12"` runs the scenario at line 12 of a feature file. The line of a Scenario Outline runs all its examples, the line of an example row runs only that example.
- ✨ `test()` and `run()` get a `fail_fast` argument. After the first failed scenario, the remaining scenarios are skipped and their hooks don't run. With `strict = TRUE`, a scenario with a pending or undefined step counts as failed.
- ✨ `test()` and `run()` get a `retry` argument. A failed scenario runs again, up to `retry` more times, until it passes, and its last attempt is its result. Pending, undefined and ambiguous scenarios aren't retried. Each attempt is reported, with `(attempt 2)` after the scenario's name, and the summary counts only the last attempt.
- ✨ `test()` and `run()` get an `order` argument. `order = "reverse"` runs the scenarios of all feature files in reverse order, `order = "random"` in random order, to show scenarios that depend on another one running first. A random order shows its seed, and `order = "random:<seed>"` runs the scenarios in that order again.
- ✨ `test()` runs feature files from the directory set in the `cucumber.path` option when called without `path`, e.g. `options(cucumber.path = "features")`. It defaults to `"tests/acceptance"`, the previous default value.

## Hooks

- ⚠️ A hook's second argument is the scenario instead of its name: a list with its `name`, `tags` and `uri`, and in `after()` hooks its `status` and `error`. Replace `scenario_name` with `scenario$name`. The status is the worst result of the scenario's steps and of the hooks that ran before, including earlier `after()` hooks.
- ✨ Define any number of `before()` and `after()` hooks. Before hooks run in the order they are defined, after hooks in the reverse order. Previously a second hook of the same kind failed with "Hook already registered".
- ✨ `before_step()` and `after_step()` hooks run around each step. They get the step's `keyword` and `text`, and in `after_step()` its `status` and `error`. A failing step hook fails the step.
- ✨ `before_all()` and `after_all()` hooks run once before the first and after the last scenario of a run. They get no arguments, or a `context` to attach data to the report.
- ✨ Hooks get a `tags` argument, a tag expression. The hook runs only for scenarios that match it, e.g. `before(connect_db, tags = "@db")`.
- ✨ Hooks get a `name` argument. A named hook's errors start with its name, e.g. `Hook "Connect to the database" failed: connection refused`.
- ✨ A `before()` hook skips its scenario by calling `skip_scenario()`. The rest of the before hooks and the scenario's steps are skipped, and `after()` hooks get `"skipped"` as the scenario's `status`.
- ✨ A step can call `skip_scenario()` too. The step and the steps after it are skipped, the scenario is reported as skipped, and `after()` hooks still run.
- ✨ A failing `before()` hook reports the scenario's steps as skipped and fails the scenario.
- ⚠️ `skip_scenario()` or `testthat::skip()` in an `after()` hook skips that hook. The next `after()` hooks still run, and the scenario is reported as skipped if it didn't fail. Previously it was an error.
- ⚠️ Every `before_all()` hook runs even when one of them fails. No scenario runs, and the run fails with the first error. Previously the hooks after the failing one didn't run.

## Reporters

- ⚠️ A `CucumberReporter` gets the run as Cucumber Messages, in its `add_message(envelope)` method: each feature, scenario, step and hook, and their results. Its `start_feature()`, `end_feature()`, `start_step()` and `end_step()` methods are removed. A step's result is in its `testStepFinished` message, with a status like `"PASSED"` or `"FAILED"`, for both failed expectations and errors, and its keyword is the one it's written with, in the `gherkinDocument` message.
- ⚠️ The reporter that prints each step as it runs is renamed from `CucumberProgressReporter` to `CucumberPrettyReporter`, like Cucumber's `pretty` formatter. It prints the keyword of each step as written, each scenario with its keyword, like `Example:` or `Scenario Outline:`, and summarises the run like Cucumber, counting scenarios and steps by status, e.g. `2 scenarios (1 failed, 1 passed)`.
- ⚠️ `CucumberProgressReporter`, the default reporter, prints one line for each feature, like testthat's `ProgressReporter`, with its scenarios counted by status. The line is redrawn with a spinner while the feature runs. A scenario that didn't pass is printed as soon as it finishes, and again in the summary at the end. Use `CucumberPrettyReporter` to see every step.
- ✨ `CucumberDotsReporter` prints one character for each step and hook as it finishes, like Cucumber's `progress` formatter: `.` passed, `F` failed, `-` skipped, `P` pending, `U` undefined and `A` ambiguous.
- ✨ `CucumberProgressBarReporter` shows a bar of the steps run so far, redrawn in place, and prints each scenario that didn't pass as soon as it finishes, like Cucumber's `progress-bar` formatter.
- ✨ `CucumberSummaryReporter` prints only the summary of the run, like Cucumber's `summary` formatter.
- ✨ `CucumberPrettyReporter` prints a failed or pending hook's error, or the reason a hook skipped the scenario, where it happens, and lists it in the summary of failures. The summary shows each failed scenario once, with all its steps.
- ✨ `CucumberMessagesReporter` writes the run as [Cucumber Messages](https://github.com/cucumber/messages), one JSON message per line, like the `message` formatter of other Cucumber implementations: `test(reporter = CucumberMessagesReporter$new("cucumber.ndjson"))`. Official tools read it, like the HTML, JUnit and JSON formatters. It passes the samples of the Cucumber Compatibility Kit that cover what cucumber supports. `CucumberReporter` gets an `add_message()` method, called with each message.
- ✨ `CucumberMultiReporter` combines reporters and passes every event to each of them, e.g. to print the progress of a run and write its messages.
- ✨ `CucumberRerunReporter` writes where the scenarios that didn't pass are, like Cucumber's `rerun` formatter: a line for each feature file with the lines of its scenarios, like `basket.feature:5:14`. Pass them to `features` to run only those scenarios again: `test(features = readLines("rerun.txt"))`.
- ⚠️ Cucumber reporters are no longer testthat reporters, and testthat reporters, like `testthat::JunitReporter`, can't be passed to `test()` or `run()`: they get an error. A `CucumberReporter` gets only cucumber's events: `start_run()`, `end_run(error)` with the error that stopped the run, `add_message()` and `add_warning()` replace testthat's `start_reporter()`, `end_reporter()`, `start_test()`, `end_test()` and `add_result()`. Use `reporter = NULL` to report nothing. With `run()` in a testthat test file, the cucumber reporter prints its summary at the end of the run.
- ✨ An error of a reporter stops the run with an error naming the reporter and the event it failed in, like ``Reporter `MyReporter` failed in `add_message()`.``, even with `stop_on_failure = FALSE`. Previously testthat reported it as the failure of the scenario, and the run went on with the reporter missing events.

## Reports

- ✨ `read_messages()` reads the Cucumber Messages of a run as tibbles of its features, scenarios (each example of an outline being one) and steps and hooks, with their status, duration and error, to write a report of your own. It prints how many features and scenarios ran, by status. A retried scenario has the steps of its last attempt, and its `attempts` column tells how many it took.
- ✨ `CucumberHtmlReporter` writes the official Cucumber HTML report of a run, the page Cucumber's `html` formatter writes: one file that works offline, with every feature's results, searchable and filterable by status, text and tags.
- ✨ `CucumberJunitReporter` writes the JUnit XML report of a run, like Cucumber's official JUnit XML formatter, for CI services to show the results of the run. Each scenario is a test case, and its steps and their results are the test case's output. It replaces `testthat::JunitReporter`, which can't report a run since 3.0.0.
- ✨ `report(file)` of every reporter reports a run after it ran, from the Cucumber Messages a `CucumberMessagesReporter` stored, e.g. `CucumberHtmlReporter$new()$report("cucumber.ndjson")`.
- ✨ Steps and hooks attach data to the report with their `context`: `context$attach(data, media_type, file_name)` attaches a string or a raw vector, like a screenshot, `context$log(text)` attaches text and `context$link(url)` a link. They're reported as `attachment` Cucumber Messages, which the HTML report shows, and `CucumberPrettyReporter` prints logs and links under their step.
- 📝 The new Reports article, `vignette("reporting")`, shows how to write the HTML report of a run, attach a screenshot and the logs of a failing shinytest2 scenario to it, and keep the report of a CI run.

## Features as documentation

- ✨ `features_rd()` puts scenarios of feature files in the help page of a function, in a "Specification" section. Call it with `@eval` in the function's roxygen block, like `#' @eval cucumber::features_rd(features = "basket.feature")`. It selects scenarios like `test()`, by `features` and their lines, `filter`, `name` and `tags`. By default only scenarios tagged `@rd` are selected, set the `cucumber.rd_tags` option to use another tag expression. Name the section with `section`, or for every help page with the `cucumber.rd_section` option. Scenarios of a Rule are shown under the Rule, and of a Scenario Outline only the selected Examples, without their tags. On a pkgdown site, the scenarios are Gherkin code blocks, highlighted by the site's theme like other code.

## Snippets

- ⚠️ Snippets for undefined steps are generated like in Cucumber: parameters in the order they appear in the step, one suggestion per matching parameter type, custom parameter types used, `data_table` and `doc_string` arguments, and repeated parameter names `string`, `string2`.
- 🐛 Snippets escape `(`, `{` and `/`, so the snippet matches the step it was generated for.
- 🐛 The snippet for an undefined first step written with `*` uses `given()`. Previously it suggested `step()`, which doesn't exist.

## Bug fixes

- 🐛 A scenario whose steps pass without calling any `expect_*()` function is reported as passed. Previously testthat reported it as skipped ("empty test"), e.g. in `JunitReporter` output.
- 🐛 A step definition with the wrong number of arguments fails the step with an error that says how many arguments the step passes and the function to use, e.g. `Use \`function(int, data_table, context)\``. Previously it failed with `unused argument`. A step definition with `...` gets the step's arguments by position.
- 🐛 Defining a step without `context` as its last argument is an error that says so and the function to use, e.g. `Use \`function(n, context)\``. Previously it was a checkmate assertion error, `Must be a subset of {'n'}`.
- 🐛 `CucumberPrettyReporter` prints a step's warnings under the step. Previously they were printed above it.
- 🐛 A failed expectation, like `expect_equal()`, in a step fails the test run. Previously testthat didn't record it, so the scenario was reported as skipped.
- 🐛 `test()` passes its `...` to `grepl()` when matching `filter`, as documented, e.g. `test(filter = "ADDITION", ignore.case = TRUE)`. Previously they were ignored. An argument that isn't an argument of `test()` or `grepl()`, like a misspelled `fail_fst = TRUE`, is an error.

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
