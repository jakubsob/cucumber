# cucumber 3.0.0

- ✨ Added support for the `Rule` keyword. A `Rule` groups scenarios that illustrate one business rule, can have its own `Background` (run after the `Feature`'s one) and passes its tags to its scenarios.
- ✨ Step descriptions now support the rest of the [Cucumber Expressions](https://github.com/cucumber/cucumber-expressions) syntax: optional text `cucumber(s)`, alternative words `Enter/Return`, and the anonymous parameter `{}`, which matches anything and passes it as text. Use `\\(`, `\\{` or `\\/` to match these characters literally.
- ⚠️ Text in step descriptions is now matched literally. Previously it was treated as a regular expression, so characters like `.`, `?`, `*`, `|` or `[` could change what a step matched. Undefined parameter types, like `{colour}` without `define_parameter_type("colour", ...)`, now raise an error.
- 🐛 Missing step snippets escape `(`, `{` and `/`, so the snippet matches the step it was generated for.
- ⚠️ A step that matches more than one step definition now fails with an error listing every matching definition and where it is defined. Previously the first registered definition was silently used, unless the definitions were identical.
- ⚠️ `{float}` now matches the same values as in Cucumber Expressions: integers like `12` and exponents like `1.5E3` too. It no longer matches any character in place of the decimal point. Defining both `{int}` and `{float}` variants of the same step makes integer steps ambiguous, so keep only the `{float}` one.
- ⚠️ Feature files are parsed by a port of the [official Gherkin parser](https://github.com/cucumber/gherkin). See [New Gherkin parser](#new-gherkin-parser) below for every step that is parsed differently.
- ⚠️ Every step gets a result: passed, failed, pending, undefined, ambiguous or skipped. Steps after a step that didn't pass are reported as skipped instead of not being reported.
- ⚠️ Undefined and ambiguous steps no longer stop the run. They fail their scenario, and the other scenarios and feature files still run, so every missing step's snippet is shown. A run without any step definitions reports its steps as undefined instead of failing with "No step definitions found".
- ⚠️ `pending()` gives the step its own `pending` status and fails the scenario. Previously the scenario was skipped. Run with `strict = FALSE` to skip scenarios with pending or undefined steps instead of failing them.
- ⚠️ A step's `status` is `"failed"` for both failed expectations and errors. The `"error"` status is removed, which matters for custom reporters.
- 🐛 A failed expectation, like `expect_equal()`, in a step now fails the test run. Previously testthat didn't record it, so the scenario was reported as skipped.
- 🐛 `test()` passes its `...` to `grepl()` when matching `filter`, as documented, e.g. `test(filter = "ADDITION", ignore.case = TRUE)`. Previously they were ignored.
- ✨ A failing `before` hook reports the scenario's steps as skipped and fails the scenario.
- ✨ `test()` and `run()` get a `dry_run` argument. A dry run matches every step to a step definition and reports undefined and ambiguous steps, but runs neither steps nor hooks.
- ✨ `test()` and `run()` get `name` and `features` arguments to run only some scenarios. `name = "^Adding"` runs scenarios whose name matches a regular expression. `features = "addition.feature:12"` runs the scenario at line 12 of a feature file, like `cucumber-js features/addition.feature:12`. The line of a Scenario Outline runs all its examples, the line of an example row runs only that example.
- ✨ `test()` and `run()` get a `fail_fast` argument. After the first failed scenario, the remaining scenarios are skipped and their hooks don't run, like `cucumber-js --fail-fast`. With `strict = TRUE`, a scenario with a pending or undefined step counts as failed.
- ⚠️ `CucumberProgressReporter` summarises the run like Cucumber, counting scenarios and steps by status, e.g. `2 scenarios (1 failed, 1 passed)`.
- ⚠️ A hook's second argument is the scenario instead of its name: a list with its `name`, `tags` and `uri`, and in `after()` hooks its `status` and `error`, e.g. to take a screenshot when a scenario fails. Replace `scenario_name` with `scenario$name`.
- ✨ Define any number of `before()` and `after()` hooks. Before hooks run in the order they are defined, after hooks in the reverse order. Previously a second hook of a kind failed with "Hook already registered".
- ✨ `before()`, `after()` and the new step hooks get a `tags` argument, a tag expression. The hook runs only for scenarios that match it, e.g. `before(connect_db, tags = "@db")`.
- ✨ `before_step()` and `after_step()` hooks run around each step. They get the step's `keyword` and `text`, and in `after_step()` its `status` and `error`. A failing step hook fails the step.
- ✨ `before_all()` and `after_all()` hooks run once before the first and after the last scenario of a run.
- ✨ A step description that starts with `^`, ends with `$` or is surrounded by `/` is a regular expression, as in cucumber-jvm. Each capture group's text is passed to the step, `NA` if the group didn't match. A group whose regexp is a parameter type's regexp, like `(\d+)` for `{int}`, is transformed by that parameter type. ⚠️ Descriptions starting with `^` or ending with `$` were Cucumber Expressions before.
- ⚠️ Invalid Cucumber Expressions are an error that points at the problem, like in Cucumber: an empty optional `()`, an optional inside an optional, a parameter inside an optional, an alternation inside an optional, an empty alternative (`/about`, `a//b`, `{int}/{int}`), an alternative made of optionals only, a missing `)` or `}`, an illegal character in a parameter name, and escaping a character that can't be escaped. Escape a literal `/` with `\\/`, e.g. `"I visit \\/about"`. When the message suggests an escape, it also shows how to write it in an R string.
- ✨ A backslash-escaped space keeps words together in an alternative: `"I live in New\\ York/Boston"` matches `I live in New York` and `I live in Boston`. Without the backslash, `New` would be outside the alternative.
- ⚠️ `{int}` matches `-?\d+` like Cucumber Expressions, so `+5` no longer matches. A value out of R's integer range fails the step instead of becoming `NA`.
- ⚠️ `{word}` matches anything without whitespace, like `foo-bar` or `a.b`. Before, it matched only letters, digits and `_`.
- ✨ `{string}` matches strings with escaped quotes, like `"say \"hi\""`, and passes them unescaped: `say "hi"`.
- ⚠️ A parameter type's `regexp` is used as is. Before, it was a replacement string, so special characters needed four backslashes. Replace `"\\\\d+"` with `"\\d+"`.
- ⚠️ If a parameter type's `regexp` has capture groups, its transformer gets the text of each group as a separate argument, like in Cucumber. Before, it got the whole match and later parameters of the step got wrong values. Use non-capturing groups, `(?:...)`, to keep the whole match.
- ✨ `define_parameter_type()` accepts several regexps and gets the `use_for_snippets` and `prefer_for_regexp_match` options.
- ⚠️ Snippets for undefined steps are generated like cucumber-js. Parameters are in the order they appear in the step, not grouped by type. A value matched by several parameter types gives one suggestion per type, e.g. `{int}` and a commented-out `{float}` for `5`. Custom parameter types are used in snippets. Repeated parameter names are `string`, `string2` instead of `string_1`, `string_2`. A step with a data table or doc string gets a `dataTable` or `docString` argument. Escaped quotes in the step's text are handled.

## New Gherkin parser

A line's meaning now comes from the keyword it starts with, not from its indentation. For the official Gherkin test data, the package gives the same scenarios, steps, arguments and errors as the official parser. Feature files that ran before can now fail to parse, and some steps get different text or arguments. Every difference is listed below with an example.

### Indentation doesn't matter

Tabs, 4 spaces, no indentation and mixed indentation are all valid. The `cucumber.indent` option is removed: it's ignored if set.

```gherkin
Feature: Basket
Scenario: Add an item
Given an empty basket
```

Before: `All lines must be indented with ^\s{2}`. Now: runs.

### Steps that were dropped and now run

- A step indented deeper than the step above it. Before, `Then b` was dropped without a warning:

  ```gherkin
      Given a
        Then b
  ```

- A Doc String with a media type after `"""`. Before, the step got no Doc String. Now it gets `{"a": 1}` (the media type isn't passed to the step):

  ```gherkin
      Given a request
        """json
        {"a": 1}
        """
  ```

  ```` ```json ```` worked before and still does.

- A step with both a Data Table and a Doc String gets both, in the order they are written. Before, it got neither:

  ```gherkin
      Given a request
        | header | value |
        | Accept | json  |
        """
        {"id": 1}
        """
  ```

  ```r
  given("a request", function(headers, body, context) { ... })
  ```

### Steps with different text

| Line in a scenario | Before | Now |
|---|---|---|
| `Given a<TAB>b   ` | step `a` (text cut at the tab) | step `a<TAB>b` (only leading and trailing whitespace is trimmed) |
| `Step one` right after `Scenario:` | step `one` | description line, not a step (`Step` isn't a Gherkin keyword) |
| `Step one` after a step | step `one` | parse error |
| `Givenfoo` after a step | step `foo` | parse error (a step keyword is followed by a space) |
| `Given: x` after a step | step `: x` | parse error |
| `Given` alone after a step | step with empty text | parse error |
| `given b` after a step | dropped | parse error (keywords are case-sensitive) |

### Scenario Outlines

- Placeholders are replaced in Doc Strings and Data Tables, not only in the step text. With `| x |` / `| 1 |` as Examples, the Doc String below is `v=1` and the table is `| 1 |` / `| 1 |`. Before, they were `v=<x>` and `| <x> |` / `| <x> |`:

  ```gherkin
    Scenario Outline: S
      Given t
        """
        v=<x>
        """
      And u
        | <x> |
        | <x> |
  ```

- Examples can have a description. Before, the description was read as table rows, so the scenarios ran with `<x>` not replaced:

  ```gherkin
      Examples: Some
        A description.
        | x |
        | 1 |
  ```

- `Examples:` under a `Scenario:` makes it an outline, like `Scenario Outline:` does. Before, `Examples:` became a step with the table as its argument and `<x>` wasn't replaced:

  ```gherkin
    Scenario: S
      Given <x>

      Examples:
        | x |
        | 1 |
        | 2 |
  ```

- ⚠️ Scenario names are the outline name with placeholders replaced, without an `(Example n)` suffix. `Scenario Outline: eat <n>` with two Examples tables runs `eat 1` and `eat 2`. Before, it ran `eat <n> (Example 1)` twice, because the counter restarted in each Examples table.
- ⚠️ Scenarios that share a name, like the rows of an outline without placeholders in its name, are numbered in test results: `eating (1)`, `eating (2)`. testthat merges the results of tests with the same name, so before, results of repeated names were lost.

### Step arguments with different values

| Feature file | Before | Now |
|---|---|---|
| Doc String with an empty line and a line starting with `#` | both lines dropped: `"x <- 1"` | kept: `c("# comment", "", "x <- 1")` |
| Doc String with `\"\"\"` inside | `say \"\"\"` | `say """` |
| Doc String whose `"""` is indented 4 spaces past its step | 2 extra spaces on each line: `c("  x", "    y")` | dedented relative to the `"""`: `c("x", "  y")` |
| Table cell `a\nb` | `a\nb` (a backslash and `n`) | `a` and `b` separated by a newline |
| Table cell `a\\b` | `a\\b` | `a\b` |
| Table header `\| a \| \|` | columns `a`, `V2` and a deprecation warning | columns `a` and `""` |
| Table header `\| a \| a \|` | columns `a`, `V2` | columns `a`, `a` |
| Table rows `\| foo \| bar \|` / `\| boz \|` | `foo = "boz"`, `bar = "boz"` | parse error: inconsistent cell count |
| Table rows `\| a \| b \|` / `\| c \| d \| e \|` | `e` dropped with a warning | parse error: inconsistent cell count |
| Table rows `\| a \| b \|` / `\| c \| d` | table dropped | parse error: inconsistent cell count |
| Table row `\| a \| b \| note` | table dropped | `note` is ignored, the table has columns `a` and `b` |

### Feature files that were accepted and now fail

These were ignored without a warning, so their steps never ran. Now they fail with a parse error:

- A line that isn't a step, a table or a Doc String between steps.
- A `Background:` after a `Scenario:`, or a second `Background:`.
- A Doc String that isn't closed before the end of the file.
- A tag at the end of the file, with no `Scenario:`, `Rule:` or `Examples:` after it.
- Two Doc Strings after one step. Before, they were merged into one Doc String.
- A tag with whitespace, like `@with space`. Before, it was the tag `@with`.
- `# language: fr`, or any language other than `en`, fails with `Language not supported: fr`. Before, the line was read as a comment.

### Feature files that failed and now run

- An empty file, a file with only comments, and a `Feature:` without scenarios run nothing.
- A `Scenario:` without steps is reported as an empty test. Before, the whole file failed with `Error tokenizing Gherkin, no keywords found`. Background steps don't run for it.
- `Feature:` in a description line, like `A Feature: in the description.`, no longer counts as a second Feature.
- `Ability:` and `Business Need:` can be used instead of `Feature:`.

### Other differences

- Tags are everything up to whitespace: `@a#2 @a:b` are the tags `@a#2` and `@a:b`. Before, both were the tag `@a`. Text after ` #` on a tag line is a comment.
- A `Scenario:` written after a `Rule:` belongs to that Rule, whatever its indentation, so it gets the Rule's tags and Background.
- ⚠️ A step keeps the keyword it's written with. `CucumberProgressReporter` prints `And`, `But` and `*` instead of the keyword of the previous step. For custom reporters, `step$keyword` is the keyword as written and the new `step$type` is `"Context"`, `"Action"`, `"Outcome"` (for Given, When and Then steps, And and But taking the previous step's type) or `"Unknown"` (for `*`, and for And or But as the first step).
- The snippet for an undefined step starting with `And`, `But` or `*` uses `given()`, `when()` or `then()` from its type, `given()` when it's unknown. Before, it suggested `step()`, which doesn't exist.

### Errors

Every error in a file is reported, with its line and column, like the official parser does:

```
Can't parse features/broken.feature
✖ (4:5): expected: #EOF, #TableRow, #DocStringSeparator, #StepLine, #TagLine, #ExamplesLine, #ScenarioLine, #RuleLine, #Comment, #Empty, got 'this line is not a step'
✖ (9:7): inconsistent cell count within the table
```

Before, the first problem stopped parsing, mostly without a location.

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
