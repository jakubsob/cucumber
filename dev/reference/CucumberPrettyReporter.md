# Pretty Reporter for Cucumber

Prints each feature, scenario and step as it runs, then the summary of
[CucumberSummaryReporter](https://jakubsob.github.io/cucumber/dev/reference/CucumberSummaryReporter.md):

    Feature: Addition
      Scenario: Add two numbers
        [x] Given I have entered 50 into the calculator
        [x] Given I have entered 70 into the calculator
        [x] When I press add
        [x] Then the result should be 120 on the screen

## Behavior

```
```

### Feature: Pretty reporter

`CucumberPrettyReporter` prints each step as it runs, with its Doc
String or Data Table and the warnings it raised, and the error and
warnings of a hook where the hook runs. Long Doc Strings and Data Tables
can be cut short with `reporter_max_docstring_lines` and
`reporter_max_table_lines`.

#### Background:

- Given a package

#### Scenario: Each step is printed with the keyword it's written with, under its scenario and Rule

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Example: Add items
      Given an empty basket
      When I add 1 item
      And I add 1 item
      But I don't pay
      Then the basket has 2 items
      * the basket is full

    Rule: Removing items
      Scenario Outline: Remove items
        Given a basket with <n> items
        When I remove <n> items
        Then the basket has 0 items

        Examples:
          | n |
          | 1 |
  ```

- And a file named "features/setup-steps.R" with

      given("an empty basket", function(context) context$n <- 0)
      given("a basket with {int} item(s)", function(n, context) context$n <- n)
      when("I add {int} item(s)", function(n, context) context$n <- context$n + n)
      when("I remove {int} item(s)", function(n, context) context$n <- context$n - n)
      when("I don't pay", function(context) {})
      then("the basket has {int} item(s)", function(n, context) expect_equal(context$n, n))
      then("the basket is full", function(context) {})

- When I run

      test("features", reporter = CucumberPrettyReporter$new())

- Then the output includes

  ``` gherkin
  Feature: Basket
  Example: Add items
  v Given an empty basket
  v When I add 1 item
  v And I add 1 item
  v But I don't pay
  v Then the basket has 2 items
  v * the basket is full
  Rule: Removing items
  Scenario Outline: Remove items
  v Given a basket with 1 items
  v When I remove 1 items
  v Then the basket has 0 items
  ```

- And the output includes

      2 scenarios (2 passed)
      9 steps (9 passed)

#### Scenario: A step's warnings are printed under it

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add an item
      Given an empty basket
  ```

- And a file named "features/setup-steps.R" with

      given("an empty basket", function(context) warning("the basket is dusty"))

- When I run

      test("features", reporter = CucumberPrettyReporter$new())

- Then the output includes

      v Given an empty basket
      Warning:
      the basket is dusty

#### Scenario: A step's error is printed under it, after its warnings

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add an item
      Given an empty basket
  ```

- And a file named "features/setup-steps.R" with

      given("an empty basket", function(context) {
        warning("the basket is dusty")
        stop("the basket is broken")
      })

- When I run it and it fails

      test("features", reporter = CucumberPrettyReporter$new())

- Then the output includes

      x Given an empty basket
      Warning:
      the basket is dusty
      Error:
      Step "an empty basket" failed

#### Scenario: A hook's error is printed where the hook runs

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add an item
      Given an empty basket
  ```

- And a file named "features/setup-steps.R" with

      before(function(context, scenario) stop("The shop is closed"))
      given("an empty basket", function(context) {})

- When I run it and it fails

      test("features", reporter = CucumberPrettyReporter$new())

- Then the output includes these lines in order:

      Scenario: Add an item
      Error:
      Hook `before()` failed
      i Feature: basket.feature:2
      i Scenario: Add an item
      i Hook defined at: setup-steps.R:1
      Caused by error:
      ! The shop is closed
      - Given an empty basket

#### Scenario: A hook's warning is printed where the hook runs

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add an item
      Given an empty basket
  ```

- And a file named "features/setup-steps.R" with

      before(function(context, scenario) warning("The shop is busy"))
      given("an empty basket", function(context) {})

- When I run

      test("features", reporter = CucumberPrettyReporter$new())

- Then the output includes these lines in order:

      Scenario: Add an item
      Warning:
      The shop is busy
      v Given an empty basket

#### Scenario: Long Doc Strings and Data Tables are cut short

- Given a file named "features/basket.feature" with

  ```` gherkin
  Feature: Basket
    Scenario: Add items
      Given a note
        ```
        line 1
        line 2
        line 3
        ```
      And these items
        | item     |
        | cucumber |
        | tomato   |
        | pepper   |
  ````

- And a file named "features/setup-steps.R" with

      given("a note", function(doc_string, context) {})
      given("these items", function(data_table, context) {})

- When I run

      test(
        "features",
        reporter = CucumberPrettyReporter$new(
          reporter_max_docstring_lines = 1,
          reporter_max_table_lines = 2
        )
      )

- Then the output includes

      v Given a note
      ```
      line 1
      ... and 2 more line(s)
      ```
      v And these items
      | item     |
      | cucumber |
      | tomato   |
      ... and 1 more line(s)

#### Scenario: Data Table cells are printed escaped, as they are written

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add items
      Given these items
        | item     | note |
        | a\|b     | x\\y |
        | cucumber | 1\n2 |
  ```

- And a file named "features/setup-steps.R" with

      given("these items", function(data_table, context) {})

- When I run

      test("features", reporter = CucumberPrettyReporter$new())

- Then the output includes

      v Given these items
      | item     | note |
      | a\|b     | x\\y |
      | cucumber | 1\n2 |

#### Scenario: A Doc String is printed as it's written, with its delimiter, media type and empty lines

- Given a file named "features/basket.feature" with

  ```` gherkin
  Feature: Basket
    Scenario: Add items
      Given a receipt
        ```json
        {"items": 2}

        ```
      And a note
        """
        Thanks
        """
  ````

- And a file named "features/setup-steps.R" with

      given("a receipt", function(doc_string, context) {})
      given("a note", function(doc_string, context) {})

- When I run

      test("features", reporter = CucumberPrettyReporter$new())

- Then the output includes

      v Given a receipt
      ```json
      {"items": 2}```
      v And a note
      """
      Thanks
      """

#### Scenario: A Data Table and a Doc String are printed in the order they're written

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add items
      Given these items and a note
        | item     |
        | cucumber |
        """
        Fresh
        """
  ```

- And a file named "features/setup-steps.R" with

      given("these items and a note", function(data_table, doc_string, context) {})

- When I run

      test("features", reporter = CucumberPrettyReporter$new())

- Then the output includes

      v Given these items and a note
      | item     |
      | cucumber |
      """
      Fresh
      """

#### Scenario: A keyword is printed as it's written, without a space it doesn't have

- Given a file named "features/basket.feature" with

  ``` gherkin
  # language: zh-CN
  功能: 购物篮
    场景: 添加商品
      假如购物篮是空的
  ```

- And a file named "features/setup-steps.R" with

      given("购物篮是空的", function(context) {})

- When I run

      test("features", reporter = CucumberPrettyReporter$new())

- Then the output includes "v 假如购物篮是空的"

Source: `tests/acceptance/r-pretty_reporter.feature`

## See also

[CucumberReporter](https://jakubsob.github.io/cucumber/dev/reference/CucumberReporter.md)

## Super classes

[`cucumber::CucumberReporter`](https://jakubsob.github.io/cucumber/dev/reference/CucumberReporter.md)
-\>
[`cucumber::CucumberSummaryReporter`](https://jakubsob.github.io/cucumber/dev/reference/CucumberSummaryReporter.md)
-\> `CucumberPrettyReporter`

## Public fields

- `reporter_max_docstring_lines`:

  Max docstring lines to print per step

- `reporter_max_table_lines`:

  Max data table rows to print per step

- `step_warnings`:

  Warnings of the step currently executing, printed under it

- `step_attachments`:

  Lines of the attachments of the step currently executing, printed
  under it

- `printed_rule`:

  The Rule last printed in the current feature, printed again only for a
  scenario of another Rule

## Methods

### Public methods

- [`CucumberPrettyReporter$new()`](#method-CucumberPrettyReporter-new)

- [`CucumberPrettyReporter$add_warning()`](#method-CucumberPrettyReporter-add_warning)

- [`CucumberPrettyReporter$print_step_args()`](#method-CucumberPrettyReporter-print_step_args)

- [`CucumberPrettyReporter$clone()`](#method-CucumberPrettyReporter-clone)

Inherited methods

- [`cucumber::CucumberReporter$report()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberReporter.html#method-report)
- [`cucumber::CucumberReporter$start_run()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberReporter.html#method-start_run)
- [`cucumber::CucumberSummaryReporter$add_message()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberSummaryReporter.html#method-add_message)
- [`cucumber::CucumberSummaryReporter$clear()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberSummaryReporter.html#method-clear)
- [`cucumber::CucumberSummaryReporter$draw()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberSummaryReporter.html#method-draw)
- [`cucumber::CucumberSummaryReporter$end_run()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberSummaryReporter.html#method-end_run)
- [`cucumber::CucumberSummaryReporter$print_above()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberSummaryReporter.html#method-print_above)
- [`cucumber::CucumberSummaryReporter$print_counts()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberSummaryReporter.html#method-print_counts)
- [`cucumber::CucumberSummaryReporter$print_failures()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberSummaryReporter.html#method-print_failures)
- [`cucumber::CucumberSummaryReporter$print_failures_since()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberSummaryReporter.html#method-print_failures_since)
- [`cucumber::CucumberSummaryReporter$print_run_error()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberSummaryReporter.html#method-print_run_error)
- [`cucumber::CucumberSummaryReporter$print_undefined_parameter_types()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberSummaryReporter.html#method-print_undefined_parameter_types)

------------------------------------------------------------------------

### Method `new()`

Initialize the reporter

#### Usage

    CucumberPrettyReporter$new(
      show_praise = NULL,
      reporter_max_docstring_lines = getOption("cucumber.reporter_max_docstring_lines"),
      reporter_max_table_lines = getOption("cucumber.reporter_max_table_lines"),
      file = NULL
    )

#### Arguments

- `show_praise`:

  Deprecated, has no effect: the reporter shows no praise.

- `reporter_max_docstring_lines`:

  Max docstring lines to print for a step before truncating. Defaults to
  the `cucumber.reporter_max_docstring_lines` option, see
  [opts](https://jakubsob.github.io/cucumber/dev/reference/opts.md).

- `reporter_max_table_lines`:

  Max data table rows to print for a step before truncating. Defaults to
  the `cucumber.reporter_max_table_lines` option, see
  [opts](https://jakubsob.github.io/cucumber/dev/reference/opts.md).

- `file`:

  Path of a file to print to instead of the console, replaced by each
  run, or `NULL`

------------------------------------------------------------------------

### Method `add_warning()`

Keep a step's warnings to print them under it, print the others as
they're raised

#### Usage

    CucumberPrettyReporter$add_warning(warning)

#### Arguments

- `warning`:

  The warning

------------------------------------------------------------------------

### Method `print_step_args()`

Print a step's docstring and/or data table arguments as they're written,
indented and truncated to `reporter_max_docstring_lines` /
`reporter_max_table_lines`

#### Usage

    CucumberPrettyReporter$print_step_args(step)

#### Arguments

- `step`:

  The step, with its `docstring` and its `data_table` rows

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    CucumberPrettyReporter$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
cucumber::test(
  "tests/acceptance",
  reporter = cucumber::CucumberPrettyReporter$new()
)
} # }
```
