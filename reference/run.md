# Run Cucumber tests in a `testthat` context

It's purpose is to be able to run Cucumber tests alongside `testthat`
tests.

To do that, place a call to `run()` in one of the `test-*.R` files in
your `tests/testthat` directory.

## Usage

``` r
run(path = ".", filter = NULL, tags = NULL, reporter = get_reporter(), ...)
```

## Arguments

- path:

  Path to the directory containing the `.feature` files. If `run()` is
  placed in a `tests/testthat/test-*.R` file and you call
  [`testthat::test_dir`](https://testthat.r-lib.org/reference/test_dir.html)
  or similar, it runs in the `tests/testthat` directory. The default
  value `"."` finds all feature files in the `tests/testthat` directory.

- filter:

  If not NULL, only features with file names matching this regular
  expression will be executed. Matching is performed on the file name
  after it's stripped of ".feature".

- tags:

  If not NULL, filter scenarios by tag expression string (e.g.,
  `"@smoke and not @slow"`, `"@gui or @database"`). Tag expressions
  support `and`, `or`, `not` operators and parentheses for grouping.

- reporter:

  Optional reporter instance (testthat::Reporter or
  cucumber::CucumberReporter). If NULL, will use reporter from package
  options if available.

- ...:

  Additional arguments passed to
  [`grepl()`](https://rdrr.io/r/base/grep.html).

## Value

NULL, invisibly. To get result and a report, use
[`cucumber::test()`](https://jakubsobolewski.com/cucumber/reference/test.md),
or inspect the result of `testthat` function call.

## Examples

``` r
if (FALSE) { # \dontrun{
#' tests/testthat/test-cucumber.R
cucumber::run()
} # }
```
