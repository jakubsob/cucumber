@rd
Feature: Pretty reporter
  `CucumberPrettyReporter` prints each step as it runs, with its Doc String or Data Table
  and the warnings it raised. Long Doc Strings and Data Tables can be cut short
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
