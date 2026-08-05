# Run Cucumber tests

It runs tests from specifications in `.feature` files found in the
`path`.

To run Cucumber tests alongside `testthat` tests, see
[`cucumber::run()`](https://jakubsobolewski.com/cucumber/reference/run.md).

## Usage

``` r
test(
  path = "tests/acceptance",
  filter = NULL,
  tags = NULL,
  reporter = get_reporter(),
  env = NULL,
  load_helpers = TRUE,
  stop_on_failure = TRUE,
  stop_on_warning = FALSE,
  ...
)
```

## Arguments

- path:

  Path to directory containing tests.

- filter:

  If not NULL, only features with file names matching this regular
  expression will be executed. Matching is performed on the file name
  after it's stripped of ".feature".

- tags:

  If not NULL, filter scenarios by tag expression string (e.g.,
  `"@smoke and not @slow"`, `"@gui or @database"`). Tag expressions
  support `and`, `or`, `not` operators and parentheses for grouping.

- reporter:

  Reporter to use to summarise output. Can be supplied as a string (e.g.
  "summary") or as an R6 object (e.g. `SummaryReporter$new()`).

  See [Reporter](https://testthat.r-lib.org/reference/Reporter.html) for
  more details and a list of built-in reporters.

- env:

  Environment in which to execute the tests. Expert use only.

- load_helpers:

  Source helper files before running the tests?

- stop_on_failure:

  If `TRUE`, throw an error if any tests fail.

- stop_on_warning:

  If `TRUE`, throw an error if any tests generate warnings.

- ...:

  Additional arguments passed to
  [`grepl()`](https://rdrr.io/r/base/grep.html) to control filtering.

## Good Practices

- Use a separate directory for your acceptance tests, e.g.
  `tests/acceptance`.

  It's not prohibited to use `tests/testthat` directory, but it's not
  recommended as those tests serve a different purpose and are better
  run separately, especially if acceptance tests take longer to run than
  unit tests.

  If you want to run Cucumber tests alongside `testthat` tests, you can
  use
  [`cucumber::run()`](https://jakubsobolewski.com/cucumber/reference/run.md)
  in one of the `test-*.R` files in your `tests/testthat` directory.

- Use
  [`setup-*.R`](https://testthat.r-lib.org/articles/special-files.html#setup-files)
  files for calling
  [`step()`](https://jakubsobolewski.com/cucumber/reference/step.md),
  [`define_parameter_type()`](https://jakubsobolewski.com/cucumber/reference/define_parameter_type.md)
  and [`hook()`](https://jakubsobolewski.com/cucumber/reference/hook.md)
  to leverage testthat loading mechanism.

  If your
  [`step()`](https://jakubsobolewski.com/cucumber/reference/step.md),
  [`define_parameter_type()`](https://jakubsobolewski.com/cucumber/reference/define_parameter_type.md)
  and [`hook()`](https://jakubsobolewski.com/cucumber/reference/hook.md)
  are called from somewhere else, you are responsible for loading them.

  Read more about testthat special files in the [testthat
  documentation](https://testthat.r-lib.org/articles/special-files.html).

- Use `test-*.R` files to test the support code you might have
  implemented that is used to run Cucumber tests.

  Those tests won't be run when calling `test()`. To run those tests use
  `testthat::test_dir("tests/acceptance")`.

## Examples

``` r
if (FALSE) { # \dontrun{
cucumber::test("tests/acceptance")
cucumber::test("tests/acceptance", filter = "addition|multiplication")

# Tag expressions
cucumber::test("tests/acceptance", tags = "@smoke")
cucumber::test("tests/acceptance", tags = "@smoke and @fast")
cucumber::test("tests/acceptance", tags = "@wip and not @slow")
cucumber::test("tests/acceptance", tags = "(@smoke or @ui) and (not @slow)")
} # }
```
