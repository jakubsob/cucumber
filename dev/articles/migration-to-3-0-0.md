# What’s new in 3.0.0 and how to migrate

Cucumber 3.0.0 brings the package closer to the official Cucumber
implementations: feature files are parsed by a port of the [official
Gherkin parser](https://github.com/cucumber/gherkin) and step
descriptions are [Cucumber
Expressions](https://github.com/cucumber/cucumber-expressions).

Each section below describes what’s new. Where a change can break a
project written for 2.2.0, a *Migrating from 2.2.0* subsection shows
what to change. The [last section](#summary-of-breaking-changes) lists
every breaking change, grouped by where you need to make it: feature
files, step definitions, parameter types, hooks, reporters and test
runs.

## Feature files

Feature files are parsed by a port of the official Gherkin parser. For
the official Gherkin test data, the package gives the same scenarios,
steps, arguments and errors as the official parser.

A line’s meaning comes from the keyword it starts with, not from its
indentation. Tabs, 4 spaces, no indentation and mixed indentation are
all valid:

``` gherkin
Feature: Basket
Scenario: Add an item
Given an empty basket
```

### Rules

A `Rule` groups scenarios that illustrate one business rule. It can have
its own `Background`, which runs after the `Feature`’s one, and passes
its tags to its scenarios:

``` gherkin
Feature: Basket

  Rule: An empty basket costs nothing

    Background:
      Given an empty basket

    Scenario: Checking out
      When I check out
      Then I pay 0
```

### Languages

Feature files can be written in any of the 80 languages of the official
Gherkin parser, by starting them with a `# language:` line. Step
definitions don’t change:

``` gherkin
# language: fr
Fonctionnalité: Panier
  Scénario: Ajouter un article
    Soit un panier vide
    Quand j'ajoute une pomme
    Alors le panier contient 1 article
```

The `cucumber.language` option sets the language of feature files
without a `# language:` line:

``` r

options(cucumber.language = "fr")
```

### Markdown with Gherkin

`.feature.md` files run like feature files. Their headers are the
Feature, Rule, Background, Scenario and Examples, their list items that
start with a step keyword are steps, their code blocks are Doc Strings,
and their tables indented 2 to 5 spaces are Data Tables and Examples.
Tags are written in backticks. The rest of the Markdown is ignored, like
in Cucumber:

``` markdown
# Feature: Basket

## Scenario: Add an item

* Given an empty basket
* When I add an apple
* Then the basket contains 1 item
```

### Scenario Outlines

- Placeholders are replaced in Doc Strings and Data Tables, not only in
  the step text. With `| x |` / `| 1 |` as Examples, the Doc String
  below is `v=1` and the table is `| 1 |` / `| 1 |`:

  ``` gherkin
    Scenario Outline: S
      Given t
        """
        v=<x>
        """
      And u
        | <x> |
        | <x> |
  ```

- Examples can have a description:

  ``` gherkin
      Examples: Some
        A description.
        | x |
        | 1 |
  ```

- `Examples:` under a `Scenario:` makes it an outline, like
  `Scenario Outline:` does.

### Step arguments

- A step can have both a Data Table and a Doc String. The step gets them
  in the order they are written:

  ``` gherkin
      Given a request
        | header | value |
        | Accept | json  |
        """
        {"id": 1}
        """
  ```

  ``` r

  given("a request", function(headers, body, context) { ... })
  ```

- A step gets a Doc String as one string, with its lines joined by
  `"\n"`, instead of a character vector of lines. Its media type,
  written after `"""` like `"""json`, is in the `media_type` attribute:

  ``` r

  given("a request", function(body, context) {
    attr(body, "media_type") # "json"
    jsonlite::fromJSON(body)
  })
  ```

  To keep getting a character vector of lines, set the
  `cucumber.docstring_as_lines` option, e.g. in a `setup-*.R` file next
  to your feature files:

  ``` r

  options(cucumber.docstring_as_lines = TRUE)
  ```

### Other additions

- `Ability:` and `Business Need:` can be used instead of `Feature:`.
- An empty file, a file with only comments, and a `Feature:` without
  scenarios run nothing, instead of failing.
- A `Scenario:` without steps passes. Background steps don’t run for it.

### Parse errors

Every feature file is parsed before anything runs. If any file can’t be
parsed, no scenario runs, and every error of every file is reported,
each with its line and column:

    Can't parse feature files
    ✖ Parse error in "broken.feature" (4:5): expected: #EOF, #TableRow, #DocStringSeparator, #StepLine, #TagLine, #ExamplesLine, #ScenarioLine, #RuleLine, #Comment, #Empty, got 'this line is not a step'
    ✖ Parse error in "broken.feature" (9:7): inconsistent cell count within the table

Before, the files before the broken one ran, and the files after it were
skipped.

### Migrating from 2.2.0

Feature files that ran before can now fail to parse, and some steps get
different text or arguments. Run
[`cucumber::test()`](https://jakubsob.github.io/cucumber/dev/reference/test.md)
and fix the parse errors, then check the differences below.

The `cucumber.indent` option is removed: it’s ignored if set.

#### Feature files that were accepted and now fail

These were ignored without a warning, so their steps never ran. Now they
fail with a parse error:

- A line that isn’t a step, a table or a Doc String between steps.
- A `Background:` after a `Scenario:`, or a second `Background:`.
- A Doc String that isn’t closed before the end of the file.
- A tag at the end of the file, with no `Scenario:`, `Rule:` or
  `Examples:` after it.
- Two Doc Strings after one step. Before, they were merged into one Doc
  String.
- A tag with whitespace, like `@with space`. Before, it was the tag
  `@with`.
- `# language:` with an unknown language, like `# language: xx`, fails
  with `Language not supported: xx`. Before, the line was read as a
  comment.

#### Steps that were dropped and now run

- A step indented deeper than the step above it. Before, `Then b` was
  dropped without a warning:

  ``` gherkin
      Given a
        Then b
  ```

- A step with a Doc String with a media type, or with both a Data Table
  and a Doc String. Before, the step got no argument.

- Examples with a description, and `Examples:` under a `Scenario:`.
  Before, `<x>` wasn’t replaced.

#### Steps with different text

| Line in a scenario | Before | Now |
|----|----|----|
| `Given a<TAB>b` | step `a` (text cut at the tab) | step `a<TAB>b` (only leading and trailing whitespace is trimmed) |
| `Step one` right after `Scenario:` | step `one` | description line, not a step (`Step` isn’t a Gherkin keyword) |
| `Step one` after a step | step `one` | parse error |
| `Givenfoo` after a step | step `foo` | parse error (a step keyword is followed by a space) |
| `Given: x` after a step | step `: x` | parse error |
| `Given` alone after a step | step with empty text | parse error |
| `given b` after a step | dropped | parse error (keywords are case-sensitive) |

#### Step arguments with different values

| Feature file | Before | Now |
|----|----|----|
| Doc String with an empty line and a line starting with `#` | both lines dropped: `"x <- 1"` | kept: `"# comment\n\nx <- 1"` |
| Doc String with `\"\"\"` inside | `say \"\"\"` | `say """` |
| Doc String whose `"""` is indented 4 spaces past its step | 2 extra spaces on each line: `c(" x", " y")` | dedented relative to the `"""`: `"x\n y"` |
| Table cell `a\nb` | `a\nb` (a backslash and `n`) | `a` and `b` separated by a newline |
| Table cell `a\\b` | `a\\b` | `a\b` |
| Table header `\| a \| \|` | columns `a`, `V2` and a deprecation warning | columns `a` and `""` |
| Table header `\| a \| a \|` | columns `a`, `V2` | columns `a`, `a` |
| Table rows `\| foo \| bar \|` / `\| boz \|` | `foo = "boz"`, `bar = "boz"` | parse error: inconsistent cell count |
| Table rows `\| a \| b \|` / `\| c \| d \| e \|` | `e` dropped with a warning | parse error: inconsistent cell count |
| Table rows `\| a \| b \|` / `\| c \| d` | table dropped | parse error: inconsistent cell count |
| Table row `\| a \| b \| note` | table dropped | `note` is ignored, the table has columns `a` and `b` |
| Outline step argument with `<x>` | `<x>` | the Examples value |

#### Scenario names

- Scenario names are the outline name with placeholders replaced,
  without an `(Example n)` suffix. `Scenario Outline: eat <n>` with two
  Examples tables runs `eat 1` and `eat 2`. Before, it ran
  `eat <n> (Example 1)` twice, because the counter restarted in each
  Examples table.
- Scenarios that share a name, like the rows of an outline without
  placeholders in its name, are numbered in test results: `eating (1)`,
  `eating (2)`. testthat merges the results of tests with the same name,
  so before, results of repeated names were lost.

If you filter scenarios by name, or compare test results by name, update
the names you use.

#### Tags and descriptions

- Tags are everything up to whitespace: `@a#2 @a:b` are the tags `@a#2`
  and `@a:b`. Before, both were the tag `@a`. Text after `#` on a tag
  line is a comment.
- `Feature:` in a description line, like
  `A Feature: in the description.`, no longer counts as a second
  Feature.

## Step descriptions

Step descriptions support the full [Cucumber
Expressions](https://github.com/cucumber/cucumber-expressions) syntax:

``` r

# Optional text: matches "1 cucumber" and "2 cucumbers"
given("I have {int} cucumber(s)", function(n, context) { ... })

# Alternative words: matches "I press Enter" and "I press Return"
when("I press Enter/Return", function(context) { ... })

# Escaped space keeps words together: matches "I live in New York" and "I live in Boston"
given("I live in New\\ York/Boston", function(context) { ... })

# Anonymous parameter: matches anything and passes it as text
given("I am {}", function(who, context) { ... })
```

A description that starts with `^`, ends with `$` or is surrounded by
`/` is a regular expression, as in cucumber-jvm. Each capture group’s
text is passed to the step, `NA` if the group didn’t match. A group
whose regexp is a parameter type’s regexp, like `(\d+)` for `{int}`, is
transformed by that parameter type:

``` r

# n is an integer
given("^I have (\\d+) cucumbers$", function(n, context) { ... })
```

Invalid Cucumber Expressions are an error that points at the problem: an
empty optional `()`, an optional inside an optional, a parameter inside
an optional, an alternation inside an optional, an empty alternative
(`/about`, `a//b`, `{int}/{int}`), an alternative made of optionals
only, a missing `)` or `}`, an illegal character in a parameter name,
and escaping a character that can’t be escaped. When the message
suggests an escape, it also shows how to write it in an R string.

A step that matches more than one step definition fails with an error
listing every matching definition and where it’s defined.

### Migrating from 2.2.0

#### Text is matched literally

Text in step descriptions was treated as a regular expression, so
characters like `.`, `?`, `*`, `|` or `[` could change what a step
matched. Now it’s matched literally. Use Cucumber Expressions instead:

``` r

# Before: matched "I have 3 apples" and "I have 3 apple"
given("I have {int} apples?", function(n, context) { ... })

# Now
given("I have {int} apple(s)", function(n, context) { ... })
```

`(`, `{` and `/` have a meaning in Cucumber Expressions. To match them
literally, escape them with `\\(`, `\\{` or `\\/`:

``` r

given("I visit \\/about", function(context) { ... })
```

#### Descriptions with `^` or `$`

Before, a description starting with `^` or ending with `$` was a
Cucumber Expression. Now it’s a regular expression, so its parameters
like `{int}` don’t work. Remove the anchors, or write it as a regular
expression:

``` r

# Before
given("^I have {int} cucumbers$", function(n, context) { ... })

# Now
given("I have {int} cucumbers", function(n, context) { ... })
```

#### Undefined parameter types

A step definition that uses a parameter type that isn’t defined, like
`{colour}` without `define_parameter_type("colour", ...)`, defines no
step. The steps it would match are undefined, and the summary of the run
lists the undefined parameter types. Define it, or remove the braces.

#### Ambiguous steps

Before, when a step matched more than one step definition, the first
registered one was used without a warning, unless the definitions were
identical. Now the step fails. Remove the duplicates.

A common case is defining a step for both `{int}` and
[float](https://github.com/wrathematics/float).
[float](https://github.com/wrathematics/float) now matches integers too,
so keep only the [float](https://github.com/wrathematics/float) one:

``` r

# Before
given("I pay {int} dollars", function(amount, context) { ... })
given("I pay {float} dollars", function(amount, context) { ... })

# Now
given("I pay {float} dollars", function(amount, context) { ... })
```

Use `cucumber::test(dry_run = TRUE)` to find every ambiguous and
undefined step without running any steps.

## Step definitions

### Cleanup with `context`

Code a step or a hook defers in its `context` runs when the scenario
ends, after its
[`after()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
hooks, like code deferred in a testthat test. Without `context`, it’s
undone when the step ends:

``` r

given("the shop is closed", function(context) {
  withr::local_options(shop.open = FALSE, .local_envir = context)
  testthat::local_mocked_bindings(now = function() as.POSIXct("2026-01-01 22:00"), .env = context)
})
```

An error of the deferred code is a warning of the scenario,
`Cleanup of the scenario failed`, as its steps already have their
results.

### Errors

- An error in a step is shown with its backtrace, the calls of the step
  down to where it was thrown, like an error in a testthat test.
  Cucumber’s reporters print it under the step’s error, testthat’s
  reporters show it under
  [`run()`](https://jakubsob.github.io/cucumber/dev/reference/run.md),
  and Cucumber Messages have it as the exception’s `stackTrace`.
- The error of a step or a hook names its feature file with a line, like
  `Feature: checkout/basket.feature:3`, so IDEs can open it there: the
  step’s line for a step, the scenario’s line for a hook.
- A step definition with the wrong number of arguments fails the step
  with an error that says how many arguments the step passes and the
  function to use, e.g. `` Use `function(int, data_table, context)` ``.
  Before, it failed with `unused argument`. A step definition with `...`
  gets the step’s arguments by position.
- Defining a step without `context` as its last argument is an error
  that shows the function to use, e.g. `` Use `function(n, context)` ``,
  or suggests renaming a misnamed last argument:
  `` Use `function(n, ctx, context)`, or rename `ctx` to `context` ``.
  Before, it was a checkmate error, `Must be a subset of {'n'}`.
- When no step definitions are loaded, an undefined step says to define
  them in `setup-*.R` or `helper-*.R` files of the test directory, as
  other R files there aren’t run.

## Parameter types

Built-in parameter types match the same values as in Cucumber
Expressions:

| Parameter | Matches |
|----|----|
| `{int}` | `-?\d+`. A value out of R’s integer range fails the step |
| [float](https://github.com/wrathematics/float) | integers like `12`, decimals like `-1.5` and `.5`, and exponents like `1.5E3` |
| `{word}` | anything without whitespace, like `foo-bar` or `a.b` |
| `{string}` | text in quotes, with escaped quotes: `"say \"hi\""` passes `say "hi"` |
| `{byte}`, `{short}` | like `{int}` |
| `{long}` | like `{int}`, but gives a double, as a long can be too big for an R integer |
| `{double}` | like [float](https://github.com/wrathematics/float) |

`{byte}`, `{short}`, `{long}` and `{double}` aren’t used in snippets.

[`define_parameter_type()`](https://jakubsob.github.io/cucumber/dev/reference/define_parameter_type.md)
accepts several regexps, and gets the `use_for_snippets` and
`prefer_for_regexp_match` options. Its `transformer` is optional:
without one, the step gets the text as it is.

[`define_parameter_type()`](https://jakubsob.github.io/cucumber/dev/reference/define_parameter_type.md)
fails on an empty name, as [`{}`](https://rdrr.io/r/base/Paren.html) is
the anonymous parameter type, and on an invalid regexp, with an error
that names the parameter type and says why, like
`The regexp /(green/ of parameter type {colour} is invalid.` Before, an
invalid regexp failed the steps that used it, with an error of
`stri_detect_regex()`.

An error of a transformer fails the step with
`Parameter type {colour} failed to transform "blue".`, caused by the
transformer’s error, and its backtrace is the calls of the transformer.

If a parameter type’s `regexp` has capture groups, its transformer gets
the text of each group as a separate argument, like in Cucumber:

``` r

define_parameter_type("point", "(\\d+),(\\d+)", function(x, y) c(as.integer(x), as.integer(y)))

given("the point {point}", function(point, context) { ... })
```

### Migrating from 2.2.0

#### Built-in parameter types

| Parameter | Before | Now |
|----|----|----|
| `{int}` | `+5` matched, a value out of R’s integer range became `NA` | `+5` doesn’t match, a value out of R’s integer range fails the step |
| [float](https://github.com/wrathematics/float) | needed a decimal point, which matched any character | integers match too, the decimal point must be `.` |
| `{word}` | letters, digits and `_` | anything without whitespace |

If you defined a step for both `{int}` and
[float](https://github.com/wrathematics/float), see [Ambiguous
steps](#ambiguous-steps).

#### Regexps are used as is

Before, a parameter type’s `regexp` was a replacement string, so special
characters needed four backslashes:

``` r

# Before
define_parameter_type("sci_number", "[+-]?\\\\d*\\\\.?\\\\d+", as.double)

# Now
define_parameter_type("sci_number", "[+-]?\\d*\\.?\\d+", as.double)
```

#### Capture groups

Before, a transformer got the whole match, and capture groups made later
parameters of the step get wrong values. To keep passing the whole
match, use non-capturing groups, `(?:...)`:

``` r

# Before
define_parameter_type("colour", "(dark )?(red|blue)", as.character)

# Now
define_parameter_type("colour", "(?:dark )?(?:red|blue)", as.character)
```

#### Parameter types can’t be redefined

[`define_parameter_type()`](https://jakubsob.github.io/cucumber/dev/reference/define_parameter_type.md)
fails on a name that is already defined differently, like `int`.
Defining the same parameter type again, like when a setup file is loaded
twice, replaces it. Before, the second definition silently replaced the
first. Give your parameter type its own name, e.g. `{count}`. A name
can’t contain `{`, `}`, `(`, `)`, `\` or `/`, and only one parameter
type with the same regexp can have `prefer_for_regexp_match = TRUE`.

`{byte}`, `{short}`, `{long}` and `{double}` are built in now, so a
parameter type of your own with one of these names must be renamed. A
regular expression group whose regexp is
[float](https://github.com/wrathematics/float)’s is ambiguous between
[float](https://github.com/wrathematics/float) and `{double}`.

## Running tests

Every step gets a result: passed, failed, pending, undefined, ambiguous
or skipped. Steps after a step that didn’t pass are reported as skipped.

Undefined and ambiguous steps don’t stop the run. They fail their
scenario, and the other scenarios and feature files still run, so every
missing step’s snippet is shown.

[`test()`](https://jakubsob.github.io/cucumber/dev/reference/test.md)
and [`run()`](https://jakubsob.github.io/cucumber/dev/reference/run.md)
search `path` recursively for feature files, symbolic links included.

[`test()`](https://jakubsob.github.io/cucumber/dev/reference/test.md)
and [`run()`](https://jakubsob.github.io/cucumber/dev/reference/run.md)
get new arguments:

``` r

# Match every step to a step definition, without running steps or hooks
cucumber::test(dry_run = TRUE)

# Run scenarios whose name matches a regular expression
cucumber::test(name = "^Adding")

# Run the scenario at line 12 of a feature file, or the feature files of a directory
cucumber::test(features = c("addition.feature:12", "checkout"))

# Skip the remaining scenarios after the first failed one
cucumber::test(fail_fast = TRUE)

# Run a failed scenario again, up to 2 more times
cucumber::test(retry = 2)

# Run the scenarios in reverse or random order
cucumber::test(order = "random")
```

- A dry run reports undefined and ambiguous steps, but they don’t fail
  it: their scenarios are skipped.
- The line of a Scenario Outline in `features` runs all its examples,
  the line of an example row runs only that example. An empty
  `features`, like a rerun file of a run whose scenarios passed, runs no
  scenario, and empty strings in it are ignored.
- With `fail_fast`, the remaining scenarios are skipped and their hooks
  don’t run. With `strict = TRUE`, a scenario with a pending or
  undefined step counts as failed.
- With `retry`, the last attempt of a scenario is its result. Pending,
  undefined and ambiguous scenarios aren’t retried. Each attempt is
  reported, with `(attempt 2)` after the scenario’s name, the summary
  counts only the last attempt, and testthat gets the expectations of
  only the last attempt.
- A random order shows its seed, and `order = "random:<seed>"` runs the
  scenarios in that order again.

[`test()`](https://jakubsob.github.io/cucumber/dev/reference/test.md)
called without `path` runs the feature files of the directory in the
`cucumber.path` option, `"tests/acceptance"` by default:

``` r

options(cucumber.path = "features")
```

### `test()` and `run()`

- [`test()`](https://jakubsob.github.io/cucumber/dev/reference/test.md)
  runs feature files like
  [`testthat::test_dir()`](https://testthat.r-lib.org/reference/test_dir.html)
  runs test files: in `path`, after the `helper-*.R` and `setup-*.R`
  files and before the `teardown-*.R` files. What they, steps and hooks
  defer to
  [`testthat::teardown_env()`](https://testthat.r-lib.org/reference/teardown_env.html)
  runs when
  [`test()`](https://jakubsob.github.io/cucumber/dev/reference/test.md)
  ends. Each feature file is the `file` of its scenarios’ results.
  Before,
  [`test()`](https://jakubsob.github.io/cucumber/dev/reference/test.md)
  wrote a `test-__cucumber__.R` file into `path`, which failed in a
  read-only directory.
- [`test()`](https://jakubsob.github.io/cucumber/dev/reference/test.md)
  attaches cucumber, like it attaches testthat, so setup files define
  steps without `cucumber::`, also when it’s called as
  [`cucumber::test()`](https://jakubsob.github.io/cucumber/dev/reference/test.md)
  from a package without
  [`library(cucumber)`](https://github.com/jakubsob/cucumber). Before,
  they failed with `could not find function "given"`.
- [`test()`](https://jakubsob.github.io/cucumber/dev/reference/test.md)
  checks snapshots when the `NOT_CRAN` environment variable isn’t set,
  like
  [`testthat::test_local()`](https://testthat.r-lib.org/reference/test_package.html).
  In a testthat run and in R CMD check, `NOT_CRAN` is left as it is, so
  `skip_on_cran()` still skips on CRAN.
- In
  [`test()`](https://jakubsob.github.io/cucumber/dev/reference/test.md),
  [`testthat::testing_package()`](https://testthat.r-lib.org/reference/is_testing.html)
  is the package of `path`, so
  `testthat::local_mocked_bindings(.env = context)` mocks the package’s
  functions without `.package`, and steps see its internal functions,
  like in a testthat test.
- [`test()`](https://jakubsob.github.io/cucumber/dev/reference/test.md)
  keeps the step definitions, hooks and parameter types registered
  before it, like by the setup files of a testthat run that calls it.
  Before, it cleared them.
- [`test()`](https://jakubsob.github.io/cucumber/dev/reference/test.md)
  fails with the error that stopped the run, like a feature file that
  can’t be parsed, under `Test failures.`, so it’s shown even with
  `reporter = NULL`.
- [`run()`](https://jakubsob.github.io/cucumber/dev/reference/run.md)
  runs outside of a testthat run, like in the console: it attaches
  testthat, reports with `CucumberProgressReporter`, fails with
  `Test failures.` if a scenario failed, and clears its step definitions
  and hooks when it returns. Before, it failed with “`teardown_env()`
  has not been initialized”.
- [`test()`](https://jakubsob.github.io/cucumber/dev/reference/test.md),
  [`run()`](https://jakubsob.github.io/cucumber/dev/reference/run.md)
  and
  [`features_rd()`](https://jakubsob.github.io/cucumber/dev/reference/features_rd.md)
  check their arguments before anything runs, even with
  `stop_on_failure = FALSE`. A mistake is an error that names the
  argument, like `` `dry_run` must be `TRUE` or `FALSE`. `` or
  `` `path` must be a directory. `` Before, they failed inside cucumber,
  like with `invalid argument type` or
  `cannot change working directory`.
- [`test()`](https://jakubsob.github.io/cucumber/dev/reference/test.md)
  passes its `...` to [`grepl()`](https://rdrr.io/r/base/grep.html) when
  matching `filter`, as documented,
  e.g. `test(filter = "ADDITION", ignore.case = TRUE)`. Before, they
  were ignored. An argument of neither
  [`test()`](https://jakubsob.github.io/cucumber/dev/reference/test.md)
  nor [`grepl()`](https://rdrr.io/r/base/grep.html), like a misspelled
  `fail_fst = TRUE`, is an error.
- A `test_that()` test after
  [`run()`](https://jakubsob.github.io/cucumber/dev/reference/run.md) in
  a test file is reported in the test file’s context. Before, testthat
  reported it in the context of the last feature
  [`run()`](https://jakubsob.github.io/cucumber/dev/reference/run.md)
  ran.

### Snapshots

Each feature file has a snapshot file of its own in `_snaps`, named
after the feature file’s path with its directories joined by `-`, like
testthat’s flat `_snaps`: the snapshots of `basket.feature` are in
`_snaps/basket.feature.md`, those of `checkout/basket.feature` in
`_snaps/checkout-basket.feature.md`. They’re the same whether the
feature files are run by
[`test()`](https://jakubsob.github.io/cucumber/dev/reference/test.md) or
by [`run()`](https://jakubsob.github.io/cucumber/dev/reference/run.md),
so either checks the snapshots of the other.

- `expect_snapshot()` works in steps and in
  [`before()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md),
  [`after()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md),
  [`before_step()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
  and
  [`after_step()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
  hooks. A snapshot in a
  [`before_all()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
  or
  [`after_all()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
  hook is an error, as a snapshot is of a scenario.
- A snapshot is named after its scenario, numbered like
  `Showing the basket (2)` when scenarios share a name. A retried
  scenario’s snapshots are those of its last attempt, and they’re kept
  in the order of the scenarios in the feature file, whatever the
  `order`.
- Snapshots of scenarios that didn’t run, like with `filter`, `name` or
  `tags`, are kept, and so are those of a scenario that stopped before
  them, and those of a scenario on CRAN. Scenarios that didn’t run keep
  their changed snapshots in the `.new.md` file too, so the changes
  found by two
  [`run()`](https://jakubsob.github.io/cucumber/dev/reference/run.md)
  calls of a feature are all reviewed with
  [`testthat::snapshot_review()`](https://testthat.r-lib.org/reference/snapshot_accept.html).
- Snapshots of scenarios that were renamed or removed are deleted, like
  those of a removed testthat test. A run of every scenario deletes the
  snapshot files of feature files that don’t exist anymore, and
  `expect_snapshot_file()` files that weren’t taken: announce them with
  [`testthat::announce_snapshot_file()`](https://testthat.r-lib.org/reference/expect_snapshot_file.html)
  to keep them. A run of some of the scenarios, a dry run, a run stopped
  by `fail_fast`, a run whose scenarios a
  [`before_all()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
  hook skipped, a run that stops before it starts, and a run on CI
  delete no snapshot file.
- A variant’s snapshot is in the variant’s directory, like
  `_snaps/linux/checkout-basket.feature.md`, and
  `expect_snapshot_file()` files in a directory named after the snapshot
  file, like `_snaps/checkout-basket.feature/plot.png`.
- Accept and review changed snapshots with the snapshot file’s name:
  `snapshot_accept("checkout-basket.feature", path)`, a variant’s with
  its directory,
  `snapshot_accept("linux/checkout-basket.feature", path)`, and
  `expect_snapshot_file()` files with a `/`,
  `snapshot_accept("checkout-basket.feature/", path)`. The message of a
  changed snapshot names it, also for a variant.
- Two feature files that would share a snapshot file, like
  `basket.feature` and `basket.feature.md`, stop the run with an error
  that names both.
- [`run()`](https://jakubsob.github.io/cucumber/dev/reference/run.md) or
  `test(".")` in a parallel testthat run,
  `Config/testthat/parallel: true`, is an error, as testthat would
  delete the snapshot files of the feature files.
- Skip the scenarios that take snapshots in a
  [`before_all()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
  or
  [`before()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
  hook, not with `skip()` before
  [`run()`](https://jakubsob.github.io/cucumber/dev/reference/run.md) in
  its test file, as testthat deletes the snapshot files that a run of
  every test file didn’t use.
- cucumber needs testthat 3.3.2 or later.

### Migrating from 2.2.0

#### Feature files in subdirectories run

Before, only the files directly in `path` ran, and the others were
ignored. Move `.feature` files that shouldn’t run, like test fixtures,
out of `path`.

#### Pending and undefined steps fail

Before,
[`pending()`](https://jakubsob.github.io/cucumber/dev/reference/pending.md)
skipped the scenario, and an undefined step stopped the run. Now both
fail the scenario. To skip these scenarios instead, run with
`strict = FALSE`:

``` r

cucumber::test("tests/acceptance", strict = FALSE)
```

A run without any step definitions reports its steps as undefined,
instead of failing with “No step definitions found”.

#### Tag expressions

Tag expressions are parsed like the official
[cucumber/tag-expressions](https://github.com/cucumber/tag-expressions).
Write tags with their `@`, and `and`, `or` and `not` in lowercase:

``` r

# Before
cucumber::test(tags = "smoke AND NOT slow")

# Now
cucumber::test(tags = "@smoke and not @slow")
```

A tag is everything up to whitespace or a parenthesis, so tags with `:`,
`/` or `#` work. Escape a parenthesis in a tag with a backslash:
`tags = "@wip\\(x\\)"`.

`tags` must be one tag expression, and `filter` one regular expression.
Before, only the first of several was used. Combine them:

``` r

# Before
cucumber::test(tags = c("@smoke", "not @slow"), filter = c("basket", "checkout"))

# Now
cucumber::test(tags = "@smoke and not @slow", filter = "basket|checkout")
```

An invalid tag expression fails with the official error,
e.g. `Tag expression "@a @b" could not be parsed because of syntax error: Expected operator.`,
before anything runs, even with `stop_on_failure = FALSE`.

#### Snapshot files

[`test()`](https://jakubsob.github.io/cucumber/dev/reference/test.md)
saved snapshots in `_snaps/__cucumber__.md`, and
[`run()`](https://jakubsob.github.io/cucumber/dev/reference/run.md) in
the snapshot file of the testthat file that called it, like
`_snaps/acceptance.md`. Move each scenario’s snapshots to the snapshot
file of its feature, see [Snapshots](#snapshots), before you run the
tests, or let the run save them again. A run of every scenario deletes
the old snapshot files as unused: testthat deletes
`_snaps/acceptance.md` as the snapshot file of a test file without
snapshots, and cucumber deletes `_snaps/__cucumber__.md`.

#### Failed expectations fail the run

Before, a failed expectation in a step, like `expect_equal()`, wasn’t
recorded by testthat, so the scenario was reported as skipped. Now it
fails the run, so tests that seemed to pass may fail. Its message is
like the error of a step: `Step "<text>" failed`, the scenario’s feature
and name, and where the step is defined, then the expectation’s message.

Other results that were wrong before:

- A step or a hook fails when a `test_that()` test in it fails, with
  `The test "<name>" in the step failed.` Before, the step and its
  scenario passed, while testthat reported the test in it as failed.
- A scenario whose steps pass without calling any `expect_*()` function
  is reported as passed. Before, testthat reported it as skipped (“empty
  test”).
- testthat’s reporters show a step’s error like an error in a test,
  starting with `Error: Step "<text>" failed`. Before, it started with
  the error’s classes,
  `<cucumber_step_error/rlang_error/error/condition>`.

## Hooks

- [`before()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
  and
  [`after()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
  hooks get the scenario: a list with its `name`, `tags`, `uri`, `line`
  and `id`, and in
  [`after()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
  hooks its `status` and `error`. The `line` of an example of a Scenario
  Outline is the line of its row. The status is the worst result of the
  scenario’s steps and of the hooks that ran before it.
- Define any number of hooks of each kind. Before hooks run in the order
  they are defined, after hooks in the reverse order.
- Hooks get a `tags` argument, a tag expression. The hook runs only for
  scenarios that match it.
- Hooks get a `name` argument. A named hook’s errors start with its
  name, e.g. `Hook "Connect to the database" failed`.
- [`before_step()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
  and
  [`after_step()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
  hooks run around each step. They get the step’s `keyword`, `text`,
  `line`, and its `data_table` and `doc_string` as its step definition
  gets them, and in
  [`after_step()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
  its `status` and `error`. A failing step hook fails the step.
- [`before_all()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
  and
  [`after_all()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
  hooks run once before the first and after the last scenario of a run.
  They get no arguments, or a `context` to attach data to the report.
  Every
  [`before_all()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
  hook runs even when one of them fails: then no scenario runs, and the
  run fails with the first error.
- A
  [`before()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
  hook skips its scenario by calling
  [`skip_scenario()`](https://jakubsob.github.io/cucumber/dev/reference/skip_scenario.md).
  The rest of the before hooks and the scenario’s steps are skipped, and
  [`after()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
  hooks get `"skipped"` as the scenario’s `status`. A step can call
  [`skip_scenario()`](https://jakubsob.github.io/cucumber/dev/reference/skip_scenario.md)
  too: it and the steps after it are skipped, and
  [`after()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
  hooks still run.
- `skip()` or
  [`skip_scenario()`](https://jakubsob.github.io/cucumber/dev/reference/skip_scenario.md)
  in a
  [`before_all()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
  hook skips every scenario of the run, like `skip()` at the top of a
  testthat file, e.g. `before_all(function() skip_if_offline())`. In an
  [`after()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
  hook, it skips that hook: the next
  [`after()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
  hooks still run, and the scenario is reported as skipped if it didn’t
  fail.
- A failing
  [`before()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
  hook reports the scenario’s steps as skipped and fails the scenario.
- A failing hook’s error says which hook failed, like
  `` Hook `before()` failed ``, or its name, the scenario’s feature and
  name, and where the hook is defined.
  [`after()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
  hooks get it as `scenario$error`, with the hook’s own error as its
  `parent`.
- A printed `scenario` shows its name and where it is, like
  `<scenario> "Add an item" (basket.feature:2)`. A printed `context`
  lists what steps and hooks put in it, one line each, and its methods.
  Like a tibble, it shows the first 10 items; `print(context, n = 20)`
  shows more.

``` r

before(function(context, scenario) {
  context$db <- DBI::dbConnect(RSQLite::SQLite(), ":memory:")
}, tags = "@db", name = "Connect to the database")

before(function(context, scenario) {
  if (!nzchar(Sys.getenv("API_KEY"))) skip_scenario("API_KEY is not set")
}, tags = "@api")

after(function(context, scenario) {
  if (scenario$status == "failed") message(scenario$name, " failed")
})

after_step(function(context, step) {
  message(step$text, ": ", step$status)
})
```

### Migrating from 2.2.0

A hook’s second argument is the scenario instead of its name. Replace
`scenario_name` with `scenario$name`:

``` r

# Before
after(function(context, scenario_name) {
  message("Finished ", scenario_name)
})

# Now
after(function(context, scenario) {
  message("Finished ", scenario$name)
})
```

Before, a second hook of the same kind failed with “Hook already
registered”.

## Reporters

- The default reporter, `CucumberProgressReporter`, prints one line per
  feature with its scenarios counted by status, like testthat’s
  `ProgressReporter`, redrawn with a spinner while the feature runs. A
  scenario that didn’t pass is printed as soon as it finishes, and again
  in the summary. The reporter that printed each step is now
  `CucumberPrettyReporter`, like Cucumber’s `pretty` formatter.
- [`run()`](https://jakubsob.github.io/cucumber/dev/reference/run.md) in
  a testthat file reports nothing of its own by default: testthat’s
  reporter reports each scenario as a test, and a failed expectation
  names its step, like `Step "the result is 2" failed`. Pass a reporter
  to [`run()`](https://jakubsob.github.io/cucumber/dev/reference/run.md)
  to print the run with cucumber’s reporter too.
- testthat’s reporters show a scenario’s failure, skip or warning at its
  line of the feature file, like `Failure ('basket.feature:4:1')`: the
  line of the step, or of the scenario for a hook. Before, they showed
  the line of the test file that called
  [`run()`](https://jakubsob.github.io/cucumber/dev/reference/run.md).
- Cucumber reporters aren’t testthat reporters anymore, and testthat
  reporters can’t report a cucumber run. A `CucumberReporter` gets the
  start and the end of the run, `start_run()` and `end_run(error)`, its
  warnings, `add_warning()`, and the run as [Cucumber
  Messages](https://github.com/cucumber/messages), `add_message()`: each
  feature, scenario, step and hook, and their results. Use
  `reporter = NULL` to report nothing.
- `CucumberPrettyReporter` prints each step with the keyword it’s
  written with, its Doc String and Data Table as written, each scenario
  with its keyword, like `Example:` or `Scenario Outline:`, the `Rule:`
  before its first scenario, a step’s warnings under the step, and a
  failed hook’s error where it happens. It summarises the run like
  Cucumber, counting scenarios and steps by status,
  e.g. `2 scenarios (1 failed, 1 passed)`. Before, a step’s warnings
  were printed above it.
- An error of a reporter stops the run with an error that names the
  reporter and the event, like
  `` Reporter `MyReporter` failed in `add_message()`. ``, even with
  `stop_on_failure = FALSE`. Before, testthat reported it as the failure
  of the scenario.

New reporters, like the formatters of Cucumber:

| Reporter | Like Cucumber’s | Reports |
|----|----|----|
| `CucumberDotsReporter` | `progress` | one character per step and hook: `.` passed, `F` failed, `-` skipped, `P` pending, `U` undefined, `A` ambiguous |
| `CucumberProgressBarReporter` | `progress-bar` | a bar of the steps run so far, and each scenario that didn’t pass |
| `CucumberSummaryReporter` | `summary` | the failures, the warnings, the counts by status and how long the run took |
| `CucumberRerunReporter` | `rerun` | where the scenarios that didn’t pass are, like `basket.feature:5:14`, to pass to `features` |
| `CucumberUsageReporter` | `usage` | how each step definition was used, the slowest steps first, and unused step definitions |
| `CucumberSnippetsReporter` | `snippets` | only the snippets of undefined steps, one per step |
| `CucumberMessagesReporter` | `message` | the run as Cucumber Messages, one JSON message per line |
| `CucumberHtmlReporter` | `html` | the official Cucumber HTML report |
| `CucumberJunitReporter` | `junit` | the JUnit XML report, for CI services |
| `CucumberMultiReporter` |  | passes every event to each of its reporters |

The reporters that print, print to a file instead when given one,
e.g. `CucumberSummaryReporter$new(file = "summary.txt")`. The reporters
that write a file create its directory. `report(file)` of every reporter
reports a run after it ran, from the messages a
`CucumberMessagesReporter` stored:

``` r

cucumber::test(reporter = CucumberMultiReporter$new(list(
  CucumberProgressReporter$new(),
  CucumberMessagesReporter$new("cucumber.ndjson")
)))
CucumberHtmlReporter$new("report.html")$report("cucumber.ndjson")
```

### Migrating from 2.2.0

This matters only for custom reporters. `start_feature()`,
`end_feature()`, `start_step()` and `end_step()` are removed: read the
run from the messages in `add_message()` instead. A step’s result is in
its `testStepFinished` message, whose `testStepId` is the id of a test
step of the scenario’s `testCase`. That test step’s `pickleStepId` is
the id of a step of the scenario’s `pickle`, with the step’s text.

``` r

# Before
StatusReporter <- R6::R6Class(
  "StatusReporter",
  inherit = cucumber::CucumberReporter,
  public = list(
    end_step = function(step) message(step$text, ": ", step$status)
  )
)

# Now
StatusReporter <- R6::R6Class(
  "StatusReporter",
  inherit = cucumber::CucumberReporter,
  public = list(
    add_message = function(envelope) {
      finished <- envelope$testStepFinished
      if (!is.null(finished)) message(finished$testStepId, ": ", finished$testStepResult$status)
    }
  )
)
```

A step’s status is `"FAILED"` for both failed expectations and errors.
The `"error"` status is removed.

`show_praise` of `CucumberPrettyReporter$new()` is deprecated and warns,
as it never had an effect.

## Reports

- [`read_messages()`](https://jakubsob.github.io/cucumber/dev/reference/read_messages.md)
  reads the Cucumber Messages of a run as tibbles of its features,
  scenarios and steps and hooks, with their status, duration and error,
  to write a report of your own. A retried scenario has the steps of its
  last attempt, and its `attempts` column tells how many it took.
- Steps and hooks attach data to the report with their `context`:
  `context$attach(data, media_type, file_name)` attaches a string or a
  raw vector, like a screenshot, `context$log(text)` attaches text and
  `context$link(url)` a link. The HTML report shows them, and
  `CucumberPrettyReporter` prints logs and links under their step.

See
[`vignette("reporting")`](https://jakubsob.github.io/cucumber/dev/articles/reporting.md)
for how to write the HTML report of a run, attach a screenshot of a
failing shinytest2 scenario to it, and keep the report of a CI run.

## Features as documentation

[`features_rd()`](https://jakubsob.github.io/cucumber/dev/reference/features_rd.md)
puts scenarios of feature files in the help page of a function, in a
section named `"Behavior"` by default:

``` r

#' @eval cucumber::features_rd(features = "basket.feature")
```

It selects scenarios like
[`test()`](https://jakubsob.github.io/cucumber/dev/reference/test.md),
by `features` and their lines, `filter`, `name` and `tags`. By default
only scenarios matching `"@rd"` are selected; the `cucumber.rd_tags`
option sets another tag expression, and `section` or the
`cucumber.rd_section` option names the section. In the help page, each
feature is one block of Gherkin, as written, with only the Rules and
Backgrounds of the selected scenarios, and of a Scenario Outline only
the selected Examples. On a pkgdown site, it’s shown like Markdown with
Gherkin: headers for the feature and its Rules, Backgrounds, scenarios
and Examples, a list of steps, tables, and Doc Strings as code, Gherkin
ones highlighted. `markdown = FALSE` shows the block of Gherkin there
too.

## Snippets

Snippets for undefined steps are generated like in Cucumber:

- Parameters are in the order they appear in the step.
- A value matched by several parameter types gives one suggestion per
  type, e.g. `{int}` and a commented-out
  [float](https://github.com/wrathematics/float) for `5`.
- Custom parameter types are used.
- Repeated parameter names are `string`, `string2`.
- A step with a data table or doc string gets a `data_table` or
  `doc_string` argument.
- `(`, `{` and `/` in the step’s text are escaped, so the snippet
  matches the step it was generated for.
- A step starting with `And`, `But` or `*` gets
  [`given()`](https://jakubsob.github.io/cucumber/dev/reference/step.md),
  [`when()`](https://jakubsob.github.io/cucumber/dev/reference/step.md)
  or
  [`then()`](https://jakubsob.github.io/cucumber/dev/reference/step.md)
  from its type,
  [`given()`](https://jakubsob.github.io/cucumber/dev/reference/step.md)
  when it’s unknown.
- A step that starts with `^` or ends with `$` gets a regular expression
  of its text, like `when("^I pay 5\\$$", ...)`.
- Arguments are valid R names: `iso_date` for a parameter type
  `{iso-date}`.

## Summary of breaking changes

Everything you may need to change when upgrading from 2.2.0, grouped by
where the change goes.

### In feature files

- Fix lines that are now parse errors: text between steps that isn’t a
  step, table or Doc String, a misplaced or second `Background:`,
  unclosed Doc Strings, tags with nothing after them, two Doc Strings
  after one step, tags with spaces, unknown `# language:`, steps without
  a space after the keyword, and lowercase keywords. See [Feature files
  that were accepted and now
  fail](#feature-files-that-were-accepted-and-now-fail) and [Steps with
  different text](#steps-with-different-text).
- Give every row of a Data Table the same number of cells. See [Step
  arguments with different
  values](#step-arguments-with-different-values).
- Check steps that were silently dropped before and now run, like steps
  indented deeper than the step above. See [Steps that were dropped and
  now run](#steps-that-were-dropped-and-now-run).
- Check tags with `#` or `:` in them, and descriptions containing
  `Feature:`. See [Tags and descriptions](#tags-and-descriptions).

### In step definitions

- Replace regular expression characters in step descriptions, like
  `apples?`, with Cucumber Expressions, like `apple(s)`. See [Text is
  matched literally](#text-is-matched-literally).
- Escape literal `(`, `{` and `/` with `\\(`, `\\{` and `\\/`,
  e.g. `"I visit \\/about"`.
- Remove `^` and `$` from descriptions that use parameters like `{int}`,
  or rewrite them as regular expressions. See [Descriptions with `^` or
  `$`](#descriptions-with-or).
- Define every parameter type used in a description, or remove its
  braces. See [Undefined parameter types](#undefined-parameter-types).
- Remove step definitions that match the same step, like `{int}` and
  [float](https://github.com/wrathematics/float) variants. See
  [Ambiguous steps](#ambiguous-steps).
- Check steps that rely on `{int}` matching `+5`,
  [float](https://github.com/wrathematics/float) matching only decimals,
  or `{word}` matching only letters, digits and `_`. See [Built-in
  parameter types](#built-in-parameter-types).
- Update steps whose Data Table or Doc String values changed: Doc
  Strings keep comment and empty lines, escapes like `\n` in table cells
  are unescaped, and outline placeholders are replaced in arguments. See
  [Step arguments with different
  values](#step-arguments-with-different-values).

### In parameter types

- Replace four backslashes with two in
  [`define_parameter_type()`](https://jakubsob.github.io/cucumber/dev/reference/define_parameter_type.md)
  regexps, e.g. `"\\\\d+"` with `"\\d+"`. See [Regexps are used as
  is](#regexps-are-used-as-is).
- Replace capture groups `(...)` with non-capturing groups `(?:...)`, or
  give the transformer one argument per group. See [Capture
  groups](#capture-groups).
- Rename parameter types that redefine another one, like `int`, or that
  are now built in: `byte`, `short`, `long` and `double`. See [Parameter
  types can’t be redefined](#parameter-types-cant-be-redefined).

### In hooks

- Replace `scenario_name` with `scenario$name` in
  [`before()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
  and
  [`after()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
  hooks. See [Hooks](#hooks).

### In custom reporters

- Replace `start_feature()`, `end_feature()`, `start_step()` and
  `end_step()` with `add_message()`, reading the run from its Cucumber
  Messages. See [Reporters](#reporters).
- Inherit from `CucumberPrettyReporter` instead of
  `CucumberProgressReporter` to extend the reporter that prints each
  step. See [Reporters](#reporters).
- Replace testthat’s reporter methods with cucumber’s events:
  `start_reporter()` with `start_run()`, `end_reporter()` with
  `end_run(error)`, `start_test()` and `end_test()` with the
  `testCaseStarted` and `testCaseFinished` messages in `add_message()`,
  and warnings from `add_result()` with `add_warning()`. See
  [Reporters](#reporters).

### In test runs

- Replace testthat reporters passed to
  [`test()`](https://jakubsob.github.io/cucumber/dev/reference/test.md)
  or [`run()`](https://jakubsob.github.io/cucumber/dev/reference/run.md)
  with cucumber’s, like `CucumberSummaryReporter$new()`, or with `NULL`
  for no output. See [Reporters](#reporters).
- Replace
  [`testthat::JunitReporter`](https://testthat.r-lib.org/reference/JunitReporter.html)
  with `CucumberJunitReporter`:
  `test(reporter = CucumberJunitReporter$new("cucumber-junit.xml"))`.
- Pass `reporter = CucumberPrettyReporter$new()` to
  [`test()`](https://jakubsob.github.io/cucumber/dev/reference/test.md)
  or [`run()`](https://jakubsob.github.io/cucumber/dev/reference/run.md)
  to see each step as it runs, as before. Replace
  `CucumberProgressReporter$new()` with `CucumberPrettyReporter$new()`
  where it’s given `reporter_max_docstring_lines` or
  `reporter_max_table_lines`. `show_praise` is deprecated, as it never
  had an effect. See [Reporters](#reporters).
- Pass `reporter = CucumberProgressReporter$new()` to
  [`run()`](https://jakubsob.github.io/cucumber/dev/reference/run.md) to
  print the run with cucumber’s reporter, besides testthat’s, as before.
  See [Reporters](#reporters).
- Move snapshots from `_snaps/__cucumber__.md`, or from the snapshot
  file of the testthat file that calls
  [`run()`](https://jakubsob.github.io/cucumber/dev/reference/run.md),
  to the snapshot file of each feature, like `_snaps/basket.feature.md`.
  See [Snapshot files](#snapshot-files).
- Move `.feature` files that shouldn’t run, like test fixtures, out of
  subdirectories of the test directory. See [Feature files in
  subdirectories run](#feature-files-in-subdirectories-run).
- Implement pending and undefined steps, or run with `strict = FALSE` to
  skip their scenarios. See [Pending and undefined steps
  fail](#pending-and-undefined-steps-fail).
- Write tags in `tags` arguments with their `@`, and `and`, `or` and
  `not` in lowercase, in
  [`test()`](https://jakubsob.github.io/cucumber/dev/reference/test.md),
  [`run()`](https://jakubsob.github.io/cucumber/dev/reference/run.md)
  and hooks. Combine several tag expressions with `and`, and several
  `filter` regular expressions with `|`. See [Tag
  expressions](#tag-expressions).
- Upgrade testthat to 3.3.2 or later.
- Fix failing expectations that were reported as skipped before. See
  [Failed expectations fail the run](#failed-expectations-fail-the-run).
- Update scenario names used in `filter`, `name` or when comparing test
  results: outline scenarios no longer get an `(Example n)` suffix, and
  repeated names are numbered. See [Scenario names](#scenario-names).
