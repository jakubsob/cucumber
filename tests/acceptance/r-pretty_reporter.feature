@rd
Feature: Pretty reporter
  `CucumberPrettyReporter` prints each step as it runs, with its Doc String or Data Table
  and the warnings it raised, and the error and warnings of a hook where the hook runs. Long Doc Strings and Data Tables can be cut short
  with `reporter_max_docstring_lines` and `reporter_max_table_lines`.

  Background:
    Given a package

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
