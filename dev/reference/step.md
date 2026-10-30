# Define a step

Provide a description that matches steps in feature files and the
implementation function that will be run.

## Usage

``` r
given(description, implementation)

when(description, implementation)

then(description, implementation)
```

## Arguments

- description:

  A [Cucumber
  Expression](https://github.com/cucumber/cucumber-expressions) or a
  regular expression that matches the text of steps, without their
  keyword. Its parameters, like `{int}`, are passed to the
  implementation, see
  [`define_parameter_type()`](https://jakubsob.github.io/cucumber/dev/reference/define_parameter_type.md).

- implementation:

  A function that gets the step's parameters, then its Data Table or Doc
  String, then `context`: an environment that the steps and hooks of a
  scenario share. Its [`attach()`](https://rdrr.io/r/base/attach.html),
  [`log()`](https://rdrr.io/r/base/Log.html) and `link()` attach data to
  the report, see
  [attachments](https://jakubsob.github.io/cucumber/dev/reference/attachments.md).

## Value

A function of class `step`, invisibly. Function should be called for
side effects.

## Behavior

```
```

### Feature: Cucumber Expressions

Step descriptions are Cucumber Expressions: text in parentheses is
optional, words separated by "/" are alternatives, "{}" matches
anything, and all other text is matched literally. An invalid expression
is an error pointing at the problem.

#### Scenario: Optional text matches with or without it

- Given a package

- And a file named "features/expressions.feature" with

  ``` gherkin
  Feature: Optional text
    Scenario: Singular and plural
      Given I have 1 cucumber
      When I eat 2 cucumbers
      Then I have eaten 2 cucumbers
  ```

- And a file named "features/setup-steps.R" with

      given("I have {int} cucumber(s)", function(n, context) {
        context$n <- n
      })
      when("I eat {int} cucumber(s)", function(n, context) {
        context$eaten <- n
      })
      then("I have eaten {int} cucumber(s)", function(n, context) {
        expect_equal(context$eaten, n)
      })

- When I run

      test("features")

- Then it passes

#### Scenario: Alternative words match any of them

- Given a package

- And a file named "features/expressions.feature" with

  ``` gherkin
  Feature: Alternatives
    Scenario: Either key
      When I press the Enter key
      And I press the Return key
      Then the key was pressed 2 times
  ```

- And a file named "features/setup-steps.R" with

      when("I press the Enter/Return key", function(context) {
        context$presses <- sum(context$presses, 1)
      })
      then("the key was pressed {int} times", function(n, context) {
        expect_equal(context$presses, n)
      })

- When I run

      test("features")

- Then it passes

#### Scenario: Anonymous parameter matches anything as text

- Given a package

- And a file named "features/expressions.feature" with

  ``` gherkin
  Feature: Anonymous parameter
    Scenario: Any value
      Given the user is John Smith from 42 Street
      Then the user should be "John Smith from 42 Street"
  ```

- And a file named "features/setup-steps.R" with

      given("the user is {}", function(user, context) {
        context$user <- user
      })
      then("the user should be {string}", function(user, context) {
        expect_identical(context$user, user)
      })

- When I run

      test("features")

- Then it passes

#### Scenario: Text is matched literally, not as a regular expression

- Given a package

- And a file named "features/expressions.feature" with

  ``` gherkin
  Feature: Literal text
    Scenario: A dot
      Given the version is 1.5

    Scenario: Any character
      Given the version is 105
  ```

- And a file named "features/setup-steps.R" with

      given("the version is 1.5", function(context) {})

- When I run

      test("features", stop_on_failure = FALSE)

- Then the steps have these results:

  |                          |           |
  |--------------------------|-----------|
  | step                     | status    |
  | Given the version is 1.5 | passed    |
  | Given the version is 105 | undefined |

#### Scenario: An escaped space keeps words together in an alternative

- Given a package

- And a file named "features/expressions.feature" with

  ``` gherkin
  Feature: Alternatives with spaces
    Scenario: Either city
      Given I lived in New York
      And I lived in Boston
      Then I lived in 2 cities
  ```

- And a file named "features/setup-steps.R" with

      given("I lived in New\\ York/Boston", function(context) {
        context$cities <- sum(context$cities, 1)
      })
      then("I lived in {int} cities", function(n, context) {
        expect_equal(context$cities, n)
      })

- When I run

      test("features")

- Then it passes

Source: `tests/acceptance/cucumber_expressions.feature`

```
```

### Feature: Regular expressions

A step description that starts with "^", ends with "\$" or is surrounded
by "/" is a regular expression instead of a Cucumber Expression. Each
capture group is passed to the step. A group whose regexp is the regexp
of a parameter type, like `(\\d+)` for `{int}`, is converted like that
parameter; any other group is passed as text. A regular expression
without "^" and "\$" can match a part of the step's text.

#### Scenario: Capture groups are passed to the step, converted by parameter type

- Given a package

- And a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Colours
      Given I have a red cucumber
      And I have a green cucumber
      Then I have 2 cucumbers
  ```

- And a file named "features/setup-steps.R" with

      given("^I have a (red|green) cucumber$", function(colour, context) {
        context$colours <- c(context$colours, colour)
      })
      then("/I have (\\d+) cucumbers/", function(n, context) {
        expect_identical(n, 2L)
        expect_equal(context$colours, c("red", "green"))
      })

- When I run

      test("features")

- Then it passes

#### Scenario: A capture group that doesn't match passes NA

- Given a package

- And a file named "features/vegetables.feature" with

  ``` gherkin
  Feature: Vegetables
    Scenario: Optional groups
      Given a cucumber and a carrot
      Then the vegetables are cucumber and carrot
  ```

- And a file named "features/setup-steps.R" with

      given("^a (.*?)(?: and a (.*?))?(?: and a (.*?))?$", function(first, second, third, context) {
        context$vegetables <- c(first, second, third)
      })
      then("^the vegetables are cucumber and carrot$", function(context) {
        expect_equal(context$vegetables, c("cucumber", "carrot", NA))
      })

- When I run

      test("features")

- Then it passes

Source: `tests/acceptance/regular_expressions.feature`

```
```

### Feature: Step definition arguments

A step definition is a function. It gets the step's parameters, then its
Data Table and Doc String in the order they are written, then `context`,
in this order.

#### Background:

- Given a package

#### Scenario Outline: A step definition without `context` as its last argument is an error, \<case\>

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add items
      When I add 3 items
  ```

- And a file named "features/setup-steps.R" with

      when("I add {int} items", <definition>)

- When I run it and it fails

      test("features")

- Then it fails with

      Error in `source_dir()`:
      ! Failed to evaluate './setup-steps.R'.
      Caused by error in `when()`:
      ! A step definition must have `context` as its last argument.
      i <hint>

##### Examples:

|  |  |  |
|----|----|----|
| case | definition | hint |
| missing context | function(n) {} | Use `function(n, context)`, or rename `n` to `context`. |
| misnamed context | function(n, ctx) {} | Use `function(n, ctx, context)`, or rename `ctx` to `context`. |
| context not last | function(context, n) {} | Use `function(n, context)`. |

#### Scenario: A step definition with `...` gets any number of arguments

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add items
      When I add 3 items
  ```

- And a file named "features/setup-steps.R" with

      when("I add {int} items", function(..., context) {
        expect_equal(list(...), list(3L))
      })

- When I run

      test("features")

- Then it passes

#### Scenario: A step definition's arguments with a default value can be left out

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add items
      When I add 3 items
  ```

- And a file named "features/setup-steps.R" with

      when("I add {int} items", function(n, unit = "piece", context) {
        expect_equal(n, 3L)
        expect_equal(unit, "piece")
      })

- When I run

      test("features")

- Then it passes

Source: `tests/acceptance/r-step_definition_arguments.feature`

```
```

### Feature: Sharing state with context

Every step definition and scenario hook gets `context`. It's an
environment that steps and hooks of one scenario share. Each scenario
starts with a new, empty `context`.

Code a step or a hook defers in `context` runs when the scenario ends,
after its
[`after()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
hooks, like code deferred in a testthat test runs when the test ends.
Pass `context` to
[`withr::defer()`](https://withr.r-lib.org/reference/defer.html) or to a
`local_*()` function, like
`withr::local_options(.local_envir = context)` or
`testthat::local_mocked_bindings(.env = context)`, to undo what a step
changes when its scenario ends. Without it, the change is undone when
the step ends. An error of the deferred code is a warning of the
scenario, as its steps already have their results.

#### Background:

- Given a package

- And a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add an item
      When I add an item
      Then the basket has 1 item

    Scenario: Look into the basket
      Then the basket has 0 items
  ```

#### Scenario: Steps of a scenario share context

- Given a file named "features/setup-steps.R" with

      when("I add an item", function(context) {
        context$items <- c(context$items, "apple")
      })
      then("the basket has {int} item(s)", function(n, context) {
        expect_length(context$items, n)
      })

- When I run

      test("features")

- Then the scenarios have these results:

  |                      |        |
  |----------------------|--------|
  | scenario             | status |
  | Add an item          | passed |
  | Look into the basket | passed |

#### Scenario: Hooks share context with the steps

- Given a file named "features/setup-steps.R" with

      before(function(context, scenario) {
        context$items <- character()
      })
      after(function(context, scenario) {
        cat(scenario$name, "ends with", length(context$items), "items\n")
      })
      when("I add an item", function(context) {
        context$items <- c(context$items, "apple")
      })
      then("the basket has {int} item(s)", function(n, context) {
        expect_length(context$items, n)
      })

- When I run

      test("features")

- Then it passes

- And the output includes "Add an item ends with 1 items"

- And the output includes "Look into the basket ends with 0 items"

#### Scenario: A printed context shows what steps and hooks put in it, and its methods

- Given a file named "features/setup-steps.R" with

      when("I add an item", function(context) {
        context$items <- c("apple", "pear")
        context$total <- 2
        print(context)
      })
      then("the basket has {int} item(s)", function(n, context) {})

- When I run

      test("features", filter = "basket", name = "Add an item")

- Then the output includes these lines in order:

      <context>
      items: chr [1:2] "apple" "pear"
      total: num 2
      Methods:
      attach(data, media_type = NULL, file_name = NULL): attach a string or a raw vector to the report
      log(text): attach text to the report
      link(...): attach one or more URLs to the report

#### Scenario: A printed context shows its first 10 items and how many more there are

- Given a file named "features/setup-steps.R" with

      when("I add an item", function(context) {
        for (i in 1:12) assign(sprintf("item_%02d", i), i, envir = context)
        print(context)
        print(context, n = 12)
      })
      then("the basket has {int} item(s)", function(n, context) {})

- When I run

      test("features", filter = "basket", name = "Add an item")

- Then the output includes these lines in order:

      <context>
      item_10: int 10
      # i 2 more items
      # i Use `print(n = ...)` to see more items
      Methods:
      <context>
      item_12: int 12
      Methods:

#### Scenario: What a step defers in context runs when the scenario ends

- Given a file named "features/setup-steps.R" with

      when("I add an item", function(context) {
        withr::local_options(basket.items = 1, .local_envir = context)
      })
      then("the basket has {int} item(s)", function(n, context) {
        expect_equal(getOption("basket.items", 0), n)
      })

- When I run

      test("features")

- Then the scenarios have these results:

  |                      |        |
  |----------------------|--------|
  | scenario             | status |
  | Add an item          | passed |
  | Look into the basket | passed |

#### Scenario: What steps and hooks defer in context runs after the after hooks

Like [`withr::defer()`](https://withr.r-lib.org/reference/defer.html),
what was deferred last runs first.

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add an item
      When I add an item
  ```

- And a file named "features/setup-steps.R" with

      before(function(context, scenario) {
        withr::defer(cat("deferred by the before hook\n"), envir = context)
      })
      after(function(context, scenario) cat("after hook\n"))
      when("I add an item", function(context) {
        withr::defer(cat("deferred by the step\n"), envir = context)
      })

- When I run

      test("features")

- Then the output includes these lines in order:

      after hook
      deferred by the step
      deferred by the before hook

#### Scenario: What a step changes without context is undone when the step ends

- Given a file named "features/setup-steps.R" with

      when("I add an item", function(context) {
        withr::local_options(basket.items = 1)
      })
      then("the basket has {int} item(s)", function(n, context) {
        expect_equal(getOption("basket.items", 0), n)
      })

- And a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add an item for a moment
      When I add an item
      Then the basket has 0 items
  ```

- When I run

      test("features")

- Then the scenarios have these results:

  |                          |        |
  |--------------------------|--------|
  | scenario                 | status |
  | Add an item for a moment | passed |

#### Scenario: A function a step mocks in context stays mocked until the scenario ends

- Given a file named "R/stock.R" with

      in_stock <- function() FALSE

- And a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Apples are delivered
      When the apples are delivered
      Then apples are in stock

    Scenario: Apples aren't delivered
      Then apples aren't in stock
  ```

- And a file named "features/setup-steps.R" with

      when("the apples are delivered", function(context) {
        testthat::local_mocked_bindings(in_stock = function() TRUE, .env = context)
      })
      then("apples are in stock", function(context) {
        expect_true(in_stock())
      })
      then("apples aren't in stock", function(context) {
        expect_false(in_stock())
      })

- When I run

      pkgload::load_all(quiet = TRUE)
      test("features")

- Then the scenarios have these results:

  |                         |        |
  |-------------------------|--------|
  | scenario                | status |
  | Apples are delivered    | passed |
  | Apples aren't delivered | passed |

#### Scenario: An error of what a step deferred in context is a warning of its scenario

- Given a file named "features/setup-steps.R" with

      when("I add an item", function(context) {
        withr::defer(stop("The basket is gone"), envir = context)
      })
      then("the basket has {int} item(s)", function(n, context) {
        succeed()
      })

- When I run

      test("features")

- Then the scenarios have these results:

  |                      |        |
  |----------------------|--------|
  | scenario             | status |
  | Add an item          | passed |
  | Look into the basket | passed |

- And the scenarios have these warnings:

  |             |                                                    |
  |-------------|----------------------------------------------------|
  | scenario    | warning                                            |
  | Add an item | Cleanup of the scenario failed: The basket is gone |

Source: `tests/acceptance/r-sharing_state_with_context.feature`

```
```

### Feature: Data Tables

A Data Table is a table under a step. The step definition gets it after
the step's parameters.

#### Background:

- Given a package

#### Rule: A step definition gets the Data Table after the step's parameters

##### Scenario: A Data Table comes after the step's parameters

- Given a file named "features/table.feature" with

  ``` gherkin
  Feature: Tables
    Scenario: Table with parameter
      Given 2 items in the basket
        | item   |
        | apple  |
        | banana |
      Then verify the basket has 2 items
  ```

- And a file named "features/setup-steps.R" with

      given("{int} items in the basket", function(count, table, context) {
        context$expected_count <- count
        context$items <- table$item
      })
      then("verify the basket has {int} items", function(n, context) {
        expect_equal(length(context$items), n)
        expect_equal(context$expected_count, n)
      })

- When I run

      test("features")

- Then it passes

#### Rule: In R, a Data Table is a tibble whose first row holds the column names

##### Scenario: A step receives a Data Table as a tibble

- Given a file named "features/table.feature" with

  ``` gherkin
  Feature: Tables
    Scenario: Step with table
      Given a list of numbers
        | value |
        | 1     |
        | 2     |
        | 3     |
      Then the sum is 6
  ```

- And a file named "features/setup-steps.R" with

      given("a list of numbers", function(table, context) {
        expect_s3_class(table, "tbl_df")
        context$numbers <- as.integer(table$value)
      })
      then("the sum is {int}", function(n, context) {
        expect_equal(sum(context$numbers), n)
      })

- When I run

      test("features")

- Then it passes

Source: `tests/acceptance/data_tables.feature`

```
```

### Feature: Doc Strings

A Doc String is a block of text under a step, between \` or """
delimiters. The step definition gets it as one string, after the step's
parameters.

#### Background:

- Given a package

#### Rule: A step definition gets the Doc String as one string, after the step's parameters

##### Scenario: A step definition gets the Doc String

- Given a file named "features/docstring.feature" with

  ```` gherkin
  Feature: Doc Strings
    Scenario: Step with a Doc String
      Given a message
        ```
        Hello, world!
        ```
      Then the message is "Hello, world!"
  ````

- And a file named "features/setup-steps.R" with

      given("a message", function(message, context) {
        context$message <- message
      })
      then("the message is {string}", function(expected, context) {
        expect_identical(context$message, expected)
      })

- When I run

      test("features")

- Then it passes

#### Rule: The media type is in the string's `media_type` attribute

It is `json` for a Doc String opened with \`json.

##### Scenario: A Doc String's media type is in its media_type attribute

- Given a file named "features/docstring.feature" with

  ```` gherkin
  Feature: Doc Strings
    Scenario: A request body
      Given a body
        ```json
        {"id": 1}
        ```
      Then the body is JSON
    Scenario: Text without a media type
      Given a body
        ```
        Hello
        ```
      Then the body has no media type
  ````

- And a file named "features/setup-steps.R" with

      given("a body", function(body, context) {
        context$body <- body
      })
      then("the body is JSON", function(context) {
        expect_equal(attr(context$body, "media_type"), "json")
        expect_equal(c(context$body), "{\"id\": 1}")
      })
      then("the body has no media type", function(context) {
        expect_null(attr(context$body, "media_type"))
      })

- When I run

      test("features")

- Then the scenarios have these results:

  |                           |        |
  |---------------------------|--------|
  | scenario                  | status |
  | A request body            | passed |
  | Text without a media type | passed |

#### Rule: In R, the `cucumber.docstring_as_lines` option passes a Doc String as a character vector of lines

##### Scenario: The cucumber.docstring_as_lines option passes a Doc String as a character vector of lines

- Given a file named "features/docstring.feature" with

  ```` gherkin
  Feature: Doc Strings
    Scenario: A script
      Given a script
        ```r
        x <- 1
        y <- 2
        ```
      Then the script is a vector of lines
  ````

- And a file named "features/setup-steps.R" with

      given("a script", function(script, context) {
        context$script <- script
      })
      then("the script is a vector of lines", function(context) {
        expect_equal(c(context$script), c("x <- 1", "y <- 2"))
        expect_equal(attr(context$script, "media_type"), "r")
      })

- When I run

      withr::with_options(list(cucumber.docstring_as_lines = TRUE), test("features"))

- Then it passes

Source: `tests/acceptance/doc_string.feature`

```
```

### Feature: Passing steps

A step passes when its step definition returns without an error. A
scenario passes when all its steps pass, even if they have no
expectations. testthat reports it as passed too, not skipped like an
empty `test_that()` test.

#### Background:

- Given a package

#### Scenario: A scenario whose steps pass without expectations passes

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add an item
      Given an empty basket
      When I add an item
  ```

- And a file named "features/setup-steps.R" with

      given("an empty basket", function(context) {
        context$basket <- list()
      })
      when("I add an item", function(context) {
        context$basket <- c(context$basket, "item")
      })

- When I run

      test("features", reporter = NULL)

- Then it passes

#### Scenario: Steps run one by one, in the order they are written

- Given a file named "features/sum.feature" with

  ``` gherkin
  Feature: Sum
    Scenario: Sum should work for 2 numbers
      Given I have 1
      And I have 2
      When I add them
      Then I get 3

    Scenario: Sum should work for 3 numbers
      Given I have 1
      And I have 2
      But I have 3
      When I add them
      Then I get 6
  ```

- And a file named "features/setup-steps.R" with

      given("I have {int}", function(int, context) {
        print("given")
        context$numbers <- c(context$numbers, int)
      })when("I add them", function(context) {
        print("when")
        context$result <- sum(context$numbers)
      })then("I get {int}", function(int, context) {
        print("then")
        expect_equal(context$result, int)
      })

- When I run

      test("features", reporter = NULL)

- Then the output includes

      [1] "given"
      [1] "given"
      [1] "when"
      [1] "then"
      [1] "given"
      [1] "given"
      [1] "given"
      [1] "when"
      [1] "then"

#### Scenario: testthat reports a scenario without expectations or steps as passed

- Given a file named "tests/testthat/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add an item
      Given an empty basket
      When I add an item

    Scenario: Not written yet
  ```

- And a file named "tests/testthat/setup-steps.R" with

      given("an empty basket", function(context) {
        context$basket <- list()
      })
      when("I add an item", function(context) {
        context$basket <- c(context$basket, "item")
      })

- And a file named "tests/testthat/test-acceptance.R" with

      run()

- When I run

      testthat::test_local(reporter = "silent")

- Then it passes

- And only these scenarios ran:

  |                 |
  |-----------------|
  | scenario        |
  | Add an item     |
  | Not written yet |

Source: `tests/acceptance/passing_steps.feature`

```
```

### Feature: Failing steps

A step fails when its step definition throws an error or a failed
expectation. The steps after it are skipped, and the other scenarios
still run. A step stops at its first failed expectation: unlike in a
testthat test, the code after it doesn't run. An error names the feature
file and the line of the step that failed, like `basket.feature:3`. An
error is shown with its backtrace, the calls of the step down to where
it was thrown, like in a testthat test.

#### Background:

- Given a package

#### Scenario: Steps after a failing step are skipped

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add an item
      Given an empty basket
      When I add an item
      Then the basket has 1 item
  ```

- And a file named "features/setup-steps.R" with

      given("an empty basket", function(context) {})
      when("I add an item", function(context) {
        expect_equal(1, 2)
      })
      then("the basket has {int} item", function(n, context) {
        stop("this step must not execute")
      })

- When I run

      test("features", stop_on_failure = FALSE)

- Then the steps have these results:

  |                            |         |
  |----------------------------|---------|
  | step                       | status  |
  | Given an empty basket      | passed  |
  | When I add an item         | failed  |
  | Then the basket has 1 item | skipped |

#### Scenario: Undefined and ambiguous steps after a failing step keep their status

Like in Cucumber, they're reported as undefined and ambiguous, so
they're found in the same run.

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add an item
      When I add an item
      Then the basket is checked
      And the basket is synced twice
  ```

- And a file named "features/setup-steps.R" with

      when("I add an item", function(context) stop("the basket is full"))
      then("the basket is synced {word}", function(word, context) {})
      then("the basket is synced {}", function(x, context) {})

- When I run

      test("features", stop_on_failure = FALSE)

- Then the steps have these results:

  |                                |           |
  |--------------------------------|-----------|
  | step                           | status    |
  | When I add an item             | failed    |
  | Then the basket is checked     | undefined |
  | And the basket is synced twice | ambiguous |

#### Scenario: A step stops at its first failed expectation

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add an item
      Then the basket has an apple
  ```

- And a file named "features/setup-steps.R" with

      then("the basket has an apple", function(context) {
        context$items <- c("pear", "plum")
        expect_equal(length(context$items), 1, label = "the number of items")
        expect_equal(context$items[[1]], "apple", label = "the first item")
      })

- When I run

      test("features", stop_on_failure = FALSE)

- Then the steps have these results:

  |                              |        |
  |------------------------------|--------|
  | step                         | status |
  | Then the basket has an apple | failed |

- And the errors are

      [failure] Scenario: Add an item
      Step "the basket has an apple" failed
      i Feature: basket.feature:3
      i Scenario: Add an item
      i Step defined at: setup-steps.R:1
      Expected the number of items to equal 1.
      Differences:
      1/1 mismatches
      [1] 2 - 1 == 1

#### Scenario: A step that throws an error fails, and the other scenarios still run

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add an item
      When I add an item

    Scenario: Look into the basket
      Given an empty basket
  ```

- And a file named "features/setup-steps.R" with

      given("an empty basket", function(context) {})
      when("I add an item", function(context) {
        stop("basket is full")
      })

- When I run

      test("features", stop_on_failure = FALSE)

- Then the errors are

      [error] Scenario: Add an item
      Error: Step "I add an item" failed
      i Feature: basket.feature:3
      i Scenario: Add an item
      i Step defined at: setup-steps.R:2
      Caused by error:
      ! basket is full

- And the scenarios have these results:

  |                      |        |
  |----------------------|--------|
  | scenario             | status |
  | Add an item          | failed |
  | Look into the basket | passed |

#### Scenario: An error is shown with the errors that caused it

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Save the basket
      When I save the basket
  ```

- And a file named "features/setup-steps.R" with

      write_basket <- function() stop("the disk is full")
      when("I save the basket", function(context) {
        tryCatch(
          write_basket(),
          error = function(e) rlang::abort("The basket can't be saved.", parent = e)
        )
      })

- When I run

      test("features", stop_on_failure = FALSE)

- Then the errors are

      [error] Scenario: Save the basket
      Error: Step "I save the basket" failed
      i Feature: basket.feature:3
      i Scenario: Save the basket
      i Step defined at: setup-steps.R:2
      Caused by error:
      ! The basket can't be saved.
      Caused by error in `write_basket()`:
      ! the disk is full

#### Scenario: An error is shown with the backtrace of the step

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add an item
      When I add an item
  ```

- And a file named "features/setup-steps.R" with

      open_basket <- function() find_basket()
      find_basket <- function() stop("basket is missing")
      when("I add an item", function(context) {
        open_basket()
      })

- When I run

      test("features", stop_on_failure = FALSE)

- Then the output includes lines matching these patterns in order:

      basket is missing
      Backtrace:
      open_basket\(\)
      find_basket\(\)

Source: `tests/acceptance/failing_steps.feature`

```
```

### Feature: Undefined steps

A step that matches no step definition is undefined. It's reported with
a snippet of the missing step definition, and the other scenarios still
run.

#### Background:

- Given a package

#### Scenario: An undefined step doesn't stop the run

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add an item
      Given an empty basket
      When I add an item
      Then the basket has 1 item

    Scenario: Look into the basket
      Given an empty basket
  ```

- And a file named "features/checkout.feature" with

  ``` gherkin
  Feature: Checkout
    Scenario: Pay
      When I pay 5 euro
  ```

- And a file named "features/setup-steps.R" with

      given("an empty basket", function(context) {})

- When I run

      test("features", stop_on_failure = FALSE)

- Then it ran "Scenario: Pay"

- And the steps have these results:

  |                      |                            |           |
  |----------------------|----------------------------|-----------|
  | scenario             | step                       | status    |
  | Add an item          | Given an empty basket      | passed    |
  | Add an item          | When I add an item         | undefined |
  | Add an item          | Then the basket has 1 item | undefined |
  | Look into the basket | Given an empty basket      | passed    |
  | Pay                  | When I pay 5 euro          | undefined |

- And the output includes

      when("I pay {int} euro", function(int, context) {

Source: `tests/acceptance/undefined_step.feature`

```
```

### Feature: Step definition snippets

An undefined step is reported with a snippet of the step definition it
needs, ready to paste into a setup file. When more than one parameter
type matches a part of the step, the alternative step definitions are
listed as comments. Keep only one of them, as a step that matches
several step definitions is ambiguous.

#### Scenario: An undefined step is reported with a snippet

- Given a package

- And a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Start shopping
      Given an empty basket
  ```

- When I run

      test("features", stop_on_failure = FALSE)

- Then the steps have these results:

  |                       |           |
  |-----------------------|-----------|
  | step                  | status    |
  | Given an empty basket | undefined |

- And the errors are

      [failure] Scenario: Start shopping
      No step found for: "an empty basket"
      i Add a step definition:
        given("an empty basket", function(context) {
          pending()
        })
      i No step definitions are loaded. Define them in `setup-*.R` or `helper-*.R` files of the test directory.

#### Scenario: Alternative step definitions are listed when more than one parameter type matches

- Given a package

- And a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Count cucumbers
      Given I have 5 cucumbers in my basket
  ```

- When I run

      test("features", stop_on_failure = FALSE)

- Then the steps have these results:

  |                                       |           |
  |---------------------------------------|-----------|
  | step                                  | status    |
  | Given I have 5 cucumbers in my basket | undefined |

- And the errors are

      [failure] Scenario: Count cucumbers
      No step found for: "I have 5 cucumbers in my basket"
      i Add a step definition:
        given("I have {int} cucumbers in my basket", function(int, context) {
        # given("I have {float} cucumbers in my basket", function(float, context) {
          pending()
        })
      i No step definitions are loaded. Define them in `setup-*.R` or `helper-*.R` files of the test directory.

Source: `tests/acceptance/step_definition_snippets.feature`

```
```

### Feature: Ambiguous steps

A step must match exactly one step definition. When it matches more than
one, the step is reported as ambiguous, listing every matching
definition, and the scenario fails.

#### Scenario: A step matching two definitions fails with both definitions listed

- Given a package

- And a file named "features/user.feature" with

  ``` gherkin
  Feature: User
    Scenario: Name a user
      Given the user is "John"
  ```

- And a file named "features/setup-steps.R" with

      given("the user is {}", function(user, context) {
        context$user <- user
      })
      given("the user is {string}", function(user, context) {
        context$user <- user
      })

- When I run

      test("features", stop_on_failure = FALSE)

- Then the steps have these results:

  |                          |           |
  |--------------------------|-----------|
  | step                     | status    |
  | Given the user is "John" | ambiguous |

- And the errors are

      [failure] Scenario: Name a user
      Multiple step definitions match: "the user is "John""
      i Make the step match only one of:
      * "the user is {}" (setup-steps.R:1)
      * "the user is {string}" (setup-steps.R:4)

#### Scenario: Steps are matched without their keyword

A Given and a Then step with the same text match the same step
definitions, so choose words that tell them apart, like "my account has
a balance of £430" and "my account should have a balance of £430".

- Given a package

- And a file named "features/account.feature" with

  ``` gherkin
  Feature: Account
    Scenario: Withdraw
      Given there is money in my account
  ```

- And a file named "features/setup-steps.R" with

      given("there is money in my account", function(context) {})
      then("there is money in my account", function(context) {})

- When I run

      test("features", stop_on_failure = FALSE)

- Then the steps have these results:

  |                                    |           |
  |------------------------------------|-----------|
  | step                               | status    |
  | Given there is money in my account | ambiguous |

- And the errors are

      [failure] Scenario: Withdraw
      Multiple step definitions match: "there is money in my account"
      i Make the step match only one of:
      * "there is money in my account" (setup-steps.R:1)
      * "there is money in my account" (setup-steps.R:2)

Source: `tests/acceptance/ambiguous_step.feature`

## See also

[`define_parameter_type()`](https://jakubsob.github.io/cucumber/dev/reference/define_parameter_type.md)

## Examples

``` r
given("I have {int} cucumbers in my basket", function(n_cucumbers, context) {
  context$n_cucumbers <- n_cucumbers
})

given("I have {int} cucumbers in my basket and a table", function(n_cucumbers, table, context) {
  context$n_cucumbers <- n_cucumbers
  context$table <- table
})

when("I eat {int} cucumbers", function(n_cucumbers, context) {
  context$n_cucumbers <- context$n_cucumbers - n_cucumbers
})

then("I should have {int} cucumbers in my basket", function(n_cucumbers, context) {
  expect_equal(context$n_cucumbers, n_cucumbers)
})
```
