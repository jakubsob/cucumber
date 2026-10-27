@rd
Feature: Pretty reporter
  `CucumberPrettyReporter` prints each step as it runs, with its Doc String or Data Table
  and the warnings it raised, and the error and warnings of a hook where the hook runs. Long Doc Strings and Data Tables can be cut short
  with `reporter_max_docstring_lines` and `reporter_max_table_lines`.

  Background:
    Given a package

  Scenario: Each step is printed with the keyword it's written with, under its scenario and Rule
    Given a file named "features/basket.feature" with
      """
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
      """
    And a file named "features/setup-steps.R" with
      """
      given("an empty basket", function(context) context$n <- 0)
      given("a basket with {int} item(s)", function(n, context) context$n <- n)
      when("I add {int} item(s)", function(n, context) context$n <- context$n + n)
      when("I remove {int} item(s)", function(n, context) context$n <- context$n - n)
      when("I don't pay", function(context) {})
      then("the basket has {int} item(s)", function(n, context) expect_equal(context$n, n))
      then("the basket is full", function(context) {})
      """
    When I run
      """
      test("features", reporter = CucumberPrettyReporter$new())
      """
    Then the output includes
      """
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
      """
    And the output includes
      """
      2 scenarios (2 passed)
      9 steps (9 passed)
      """

  Scenario: A step's warnings are printed under it
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      given("an empty basket", function(context) warning("the basket is dusty"))
      """
    When I run
      """
      test("features", reporter = CucumberPrettyReporter$new())
      """
    Then the output includes
      """
      v Given an empty basket
      Warning:
      the basket is dusty
      """

  Scenario: A step's error is printed under it, after its warnings
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      given("an empty basket", function(context) {
        warning("the basket is dusty")
        stop("the basket is broken")
      })
      """
    When I run it and it fails
      """
      test("features", reporter = CucumberPrettyReporter$new())
      """
    Then the output includes
      """
      x Given an empty basket
      Warning:
      the basket is dusty
      Error:
      Step "an empty basket" failed
      """

  Scenario: A hook's error is printed where the hook runs
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      before(function(context, scenario) stop("The shop is closed"))
      given("an empty basket", function(context) {})
      """
    When I run it and it fails
      """
      test("features", reporter = CucumberPrettyReporter$new())
      """
    Then the output includes these lines in order:
      """
      Scenario: Add an item
      Error:
      Hook `before()` failed
      i Feature: basket.feature
      i Scenario: Add an item
      i Hook defined at: setup-steps.R:1
      Caused by error:
      ! The shop is closed
      - Given an empty basket
      """

  Scenario: A hook's warning is printed where the hook runs
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      before(function(context, scenario) warning("The shop is busy"))
      given("an empty basket", function(context) {})
      """
    When I run
      """
      test("features", reporter = CucumberPrettyReporter$new())
      """
    Then the output includes these lines in order:
      """
      Scenario: Add an item
      Warning:
      The shop is busy
      v Given an empty basket
      """

  Scenario: Long Doc Strings and Data Tables are cut short
    Given a file named "features/basket.feature" with
      """
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
      """
    And a file named "features/setup-steps.R" with
      """
      given("a note", function(doc_string, context) {})
      given("these items", function(data_table, context) {})
      """
    When I run
      """
      test(
        "features",
        reporter = CucumberPrettyReporter$new(
          reporter_max_docstring_lines = 1,
          reporter_max_table_lines = 2
        )
      )
      """
    Then the output includes
      """
      v Given a note
      \"\"\"
      line 1
      ... and 2 more line(s)
      \"\"\"
      v And these items
      | item     |
      | cucumber |
      | tomato   |
      ... and 1 more line(s)
      """

  Scenario: Data Table cells are printed escaped, as they are written
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add items
          Given these items
            | item     | note |
            | a\|b     | x\\y |
            | cucumber | 1\n2 |
      """
    And a file named "features/setup-steps.R" with
      """
      given("these items", function(data_table, context) {})
      """
    When I run
      """
      test("features", reporter = CucumberPrettyReporter$new())
      """
    Then the output includes
      """
      v Given these items
      | item     | note |
      | a\|b     | x\\y |
      | cucumber | 1\n2 |
      """
