# Define extra parameters to use in Cucumber steps.

Built-in parameter types are `{int}`, `{float}`, `{word}`, `{string}`
and the anonymous [`{}`](https://rdrr.io/r/base/Paren.html). `{byte}`
and `{short}` match and convert like `{int}`, and `{double}` like
`{float}`. `{long}` matches like `{int}` but gives a double, as a long
can be too big for an R integer. Define your own before the steps that
use it are run, e.g. in a `setup-*.R` file.

## Usage

``` r
define_parameter_type(
  name,
  regexp,
  transformer = function(x, ...) x,
  use_for_snippets = TRUE,
  prefer_for_regexp_match = FALSE
)
```

## Arguments

- name:

  The name of the parameter.

- regexp:

  A regular expression that the parameter will match on, or a character
  vector of them to match any of them.

- transformer:

  A function that will transform the parameter from a string to the
  desired type. If `regexp` has capture groups, the transformer gets the
  text of each of them as a separate argument instead of the whole
  match. Use non-capturing groups, `(?:...)`, to pass the whole match.
  Defaults to passing the text as it is, the text of the first capture
  group if `regexp` has any.

- use_for_snippets:

  Whether to use this parameter type in snippets suggested for undefined
  steps.

- prefer_for_regexp_match:

  Whether to use this parameter type for a regular expression step
  definition's capture group whose regexp is the same as the regexp of
  another parameter type.

## Value

An object of class `parameter`, invisibly. Function should be called for
side effects.

## Behavior

```
```

### Feature: Parameter types

A parameter like `{int}` in a step definition's Cucumber Expression
captures a part of the step and passes it to the step definition
converted to an R value. Register your own with
`define_parameter_type()`.

#### Background:

- Given a package

#### Rule: Built-in parameter types convert the text to R values

##### Scenario: {int} captures an integer from step text

- Given a file named "features/params.feature" with

  ``` gherkin
  Feature: Parameters
    Scenario: Integer parameter
      Given the count is 42
      Then I verify the count is 42
  ```

- And a file named "features/setup-steps.R" with

      given("the count is {int}", function(n, context) {
        context$value <- n
      })
      then("I verify the count is 42", function(context) {
        expect_identical(context$value, 42L)
      })

- When I run

      test("features")

- Then it passes

##### Scenario: {float} captures a decimal number from step text

- Given a file named "features/params.feature" with

  ``` gherkin
  Feature: Parameters
    Scenario: Float parameter
      Given the price is 3.99
      Then I verify the price is 3.99
  ```

- And a file named "features/setup-steps.R" with

      given("the price is {float}", function(price, context) {
        context$price <- price
      })
      then("I verify the price is 3.99", function(context) {
        expect_identical(context$price, 3.99)
      })

- When I run

      test("features")

- Then it passes

##### Scenario: {float} also captures an integer

- Given a file named "features/params.feature" with

  ``` gherkin
  Feature: Parameters
    Scenario: Integer as a float
      Given the price is 12
      Then I verify the price is 12
  ```

- And a file named "features/setup-steps.R" with

      given("the price is {float}", function(price, context) {
        context$price <- price
      })
      then("I verify the price is {float}", function(price, context) {
        expect_identical(context$price, price)
        expect_identical(context$price, 12)
      })

- When I run

      test("features")

- Then it passes

##### Scenario: {string} captures a quoted string and strips quotes

- Given a file named "features/params.feature" with

  ``` gherkin
  Feature: Parameters
    Scenario: String parameter double quotes
      Given the name is "Alice"
      Then I verify the name is "Alice"

    Scenario: String parameter single quotes
      Given the name is 'Bob'
      Then I verify the name is "Bob"
  ```

- And a file named "features/setup-steps.R" with

      given("the name is {string}", function(name, context) {
        context$name <- name
      })
      then("I verify the name is {string}", function(name, context) {
        expect_equal(context$name, name)
        expect_false(startsWith(context$name, "\""))
        expect_false(startsWith(context$name, "'"))
      })

- When I run

      test("features")

- Then the scenarios have these results:

  |                                |        |
  |--------------------------------|--------|
  | scenario                       | status |
  | String parameter double quotes | passed |
  | String parameter single quotes | passed |

##### Scenario: {word} captures a single unquoted word

- Given a file named "features/params.feature" with

  ``` gherkin
  Feature: Parameters
    Scenario: Word parameter
      Given the colour is red
      Then I verify the colour is red
  ```

- And a file named "features/setup-steps.R" with

      given("the colour is {word}", function(colour, context) {
        context$colour <- colour
      })
      then("I verify the colour is red", function(context) {
        expect_identical(context$colour, "red")
      })

- When I run

      test("features")

- Then it passes

#### Rule: {int} is an R integer

##### Scenario: {int} fails on a value too big for an R integer

- Given a file named "features/params.feature" with

  ``` gherkin
  Feature: Parameters
    Scenario: Big number
      Given the count is 3000000000
  ```

- And a file named "features/setup-steps.R" with

      given("the count is {int}", function(n, context) {})

- When I run

      test("features", stop_on_failure = FALSE)

- Then the steps have these results:

  |                               |        |
  |-------------------------------|--------|
  | step                          | status |
  | Given the count is 3000000000 | failed |

- And the errors are

      [error] Scenario: Big number
      Error: Step "the count is 3000000000" failed
      i Feature: params.feature:3
      i Scenario: Big number
      i Step defined at: setup-steps.R:1
      Caused by error:
      ! Parameter type {int} failed to transform "3000000000".
      Caused by error:
      ! It's out of the range of an R integer.

#### Rule: {byte}, {short}, {long} and {double} are built in too, for feature files shared with other Cucumber implementations

##### Scenario Outline: {\<type\>} gives \<value\>

- Given a file named "features/params.feature" with

  ``` gherkin
  Feature: Parameters
    Scenario: Number
      Given the number is <text>
  ```

- And a file named "features/setup-steps.R" with

      given("the number is {<type>}", function(x, context) {
        expect_identical(x, <value>)
      })

- When I run

      test("features")

- Then it passes

###### Examples:

|        |            |       |
|--------|------------|-------|
| type   | text       | value |
| byte   | -12        | -12L  |
| short  | 300        | 300L  |
| long   | 3000000000 | 3e9   |
| double | 1.5E3      | 1500  |

#### Rule: Custom parameter types are defined with define_parameter_type()

##### Scenario: A custom parameter type can be registered and used in steps

- Given a file named "features/params.feature" with

  ``` gherkin
  Feature: Parameters
    Scenario: Custom parameter
      Given the direction is north
      Then I verify the direction is north
  ```

- And a file named "features/setup-steps.R" with

      define_parameter_type(
        name = "direction",
        regexp = "north|south|east|west",
        transformer = toupper
      )
      given("the direction is {direction}", function(dir, context) {
        context$direction <- dir
      })
      then("I verify the direction is {direction}", function(dir, context) {
        expect_equal(context$direction, "NORTH")
      })

- When I run

      test("features")

- Then it passes

##### Scenario: A custom parameter type's regexp is a plain regular expression

- Given a file named "features/params.feature" with

  ``` gherkin
  Feature: Parameters
    Scenario: Version
      Given the version is 1.2
  ```

- And a file named "features/setup-steps.R" with

      define_parameter_type("version", "\\d+\\.\\d+", numeric_version)
      given("the version is {version}", function(version, context) {
        expect_equal(version, numeric_version("1.2"))
      })

- When I run

      test("features")

- Then it passes

##### Scenario: A custom parameter type can have several regexps

- Given a file named "features/params.feature" with

  ``` gherkin
  Feature: Parameters
    Scenario: Answers
      Given the answer is yes
      And the answer is no
  ```

- And a file named "features/setup-steps.R" with

      define_parameter_type("answer", c("yes", "no"), \(x) x == "yes")
      given("the answer is {answer}", function(answer, context) {
        context$answers <- c(context$answers, answer)
        if (length(context$answers) == 2) expect_identical(context$answers, c(TRUE, FALSE))
      })

- When I run

      test("features")

- Then it passes

##### Scenario: A custom parameter type's transformer gets the text of each capture group

- Given a file named "features/params.feature" with

  ``` gherkin
  Feature: Parameters
    Scenario: Point
      Given a point at 1,2 and 3 more
  ```

- And a file named "features/setup-steps.R" with

      define_parameter_type("point", "(\\d+),(\\d+)", function(x, y) as.integer(c(x, y)))
      given("a point at {point} and {int} more", function(point, n, context) {
        expect_equal(point, c(1L, 2L))
        expect_equal(n, 3L)
      })

- When I run

      test("features")

- Then it passes

##### Scenario: A transformer's error fails the step and names the parameter type

The error is shown with the backtrace of the transformer.

- Given a file named "features/params.feature" with

  ``` gherkin
  Feature: Parameters
    Scenario: Colour
      Given the colour is blue
  ```

- And a file named "features/setup-steps.R" with

      check_colour <- function(x) stop("Unknown colour: ", x)
      define_parameter_type("colour", "[a-z]+", function(x) check_colour(x))
      given("the colour is {colour}", function(colour, context) {})

- When I run

      test("features", stop_on_failure = FALSE)

- Then the steps have these results:

  |                          |        |
  |--------------------------|--------|
  | step                     | status |
  | Given the colour is blue | failed |

- And the errors are

      [error] Scenario: Colour
      Error: Step "the colour is blue" failed
      i Feature: params.feature:3
      i Scenario: Colour
      i Step defined at: setup-steps.R:3
      Caused by error:
      ! Parameter type {colour} failed to transform "blue".
      Caused by error in `check_colour()`:
      ! Unknown colour: blue

- And the output includes lines matching these patterns in order:

      Unknown colour: blue
      ^Backtrace:$
      1\. .*check_colour\(x\)

- And the output doesn't include "test_that"

#### Rule: A step definition with an undefined parameter type defines no step

The run goes on: the steps it would match are undefined, and the summary
lists the undefined parameter types.

##### Scenario: Steps of a step definition with an undefined parameter type are undefined

- Given a file named "features/airports.feature" with

  ``` gherkin
  Feature: Airports
    Scenario: Strike
      Given CDG is closed because of a strike

    Scenario: Open
      Given LHR is open
  ```

- And a file named "features/setup-steps.R" with

      given("{airport} is closed because of a strike", function(airport, context) {})
      given("LHR is open", function(context) {})

- When I run

      test("features", stop_on_failure = FALSE)

- Then the steps have these results:

  |          |                                         |           |
  |----------|-----------------------------------------|-----------|
  | scenario | step                                    | status    |
  | Strike   | Given CDG is closed because of a strike | undefined |
  | Open     | Given LHR is open                       | passed    |

- And the output includes

      Undefined parameter types:
      - "airport" e.g. `{airport} is closed because of a strike`

Source: `tests/acceptance/parameter_types.feature`

## Examples

``` r
define_parameter_type("color", "red|blue|green", as.character)
define_parameter_type(
  name = "sci_number",
  regexp = "[+-]?\\d*\\.?\\d+(?:e[+-]?\\d+)?",
  transformer = as.double
)

if (FALSE) { # \dontrun{
#' tests/testthat/test-cucumber.R
cucumber::define_parameter_type("color", "red|blue|green", as.character)
cucumber::test(".", "./steps")
} # }
```
