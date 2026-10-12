Feature: Gherkin
  Feature files are parsed like the official Gherkin parser does it.
  A line's meaning comes from its keyword, not from its indentation,
  and a file that isn't valid Gherkin fails with every error and its line:column.

  Background:
    Given a package

  Scenario: Indentation doesn't matter
    Given a file named "features/indent.feature" with
      """
      Feature: Indentation
      Scenario: Flat
      Given I have 1
      Then I should have 1
          Scenario: Tabs and a step deeper than the previous one
      	Given I have 1
      		Then I should have 1
      """
    And a file named "features/setup-steps.R" with
      """
      given("I have {int}", function(n, context) {
        context$n <- n
      })
      then("I should have {int}", function(n, context) {
        expect_equal(context$n, n)
      })
      """
    When I run
      """
      test("features")
      """
    Then it passes
    And it has 2 passed

  Scenario: A feature without scenarios runs nothing
    Given a file named "features/empty.feature" with
      """
      Feature: Not written yet
        Scenarios will come later.
      """
    And a file named "features/setup-steps.R" with
      """
      given("a step", function(context) {})
      """
    When I run
      """
      test("features")
      """
    Then it has 0 passed
    And the output doesn't include "Feature: Not written yet"

  Scenario: Every error in a feature file is reported with its line and column
    Given a file named "features/broken.feature" with
      """
      Feature: Broken
        Scenario: Junk between steps
          Given a step
          this line is not a step
          Then a step
        Scenario: A ragged table
          Given a step
            | a | b |
            | c |
      """
    And a file named "features/setup-steps.R" with
      """
      given("a step", function(context) {})
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then it has 1 errors
    And the error message includes
      """
      (4:5): expected: #EOF, #TableRow, #DocStringSeparator, #StepLine, #TagLine, #ExamplesLine, #ScenarioLine, #RuleLine, #Comment, #Empty, got 'this line is not a step'
      """
    And the error message includes
      """
      (9:7): inconsistent cell count within the table
      """

  Scenario: An unknown language is a parse error
    Given a file named "features/unknown.feature" with
      """
      # language: xx
      Feature: Unknown language
        Scenario: A step
          Given a step
      """
    And a file named "features/setup-steps.R" with
      """
      given("a step", function(context) {})
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then it has 1 errors
    And the error message includes "(1:1): Language not supported: xx"

  Scenario: An empty feature file runs nothing
    Given a file named "features/empty.feature" with
      """

      """
    And a file named "features/setup-steps.R" with
      """
      given("a step", function(context) {})
      """
    When I run
      """
      test("features")
      """
    Then it has 0 passed

  Scenario: A scenario without steps passes
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Not written yet
      """
    When I run
      """
      test("features")
      """
    Then it passes
    And it has 1 passed

  Scenario: A tag with whitespace is a parse error
    Given a file named "features/tagged.feature" with
      """
      @work in progress
      Feature: Tagged
        Scenario: A step
          Given a step
      """
    And a file named "features/setup-steps.R" with
      """
      given("a step", function(context) {})
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then it has 1 errors
    And the error message includes "(1:1): A tag may not contain whitespace"

  Scenario: A feature file that ends too early is a parse error
    Given a file named "features/tagged.feature" with
      """
      @wip
      """
    And a file named "features/setup-steps.R" with
      """
      given("a step", function(context) {})
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then it has 1 errors
    And the error message includes "(2:0): unexpected end of file, expected: #TagLine, #FeatureLine, #Comment"

  Scenario: Parsing stops after 10 errors
    Given a file named "features/broken.feature" with
      """
      Feature: Broken
        Scenario: Junk
          Given a step
          junk 1
          junk 2
          junk 3
          junk 4
          junk 5
          junk 6
          junk 7
          junk 8
          junk 9
          junk 10
          junk 11
          junk 12
      """
    And a file named "features/setup-steps.R" with
      """
      given("a step", function(context) {})
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then it has 1 errors
    And the error message includes "got 'junk 11'"
    And the error message doesn't include "got 'junk 12'"

  Scenario Outline: <keyword> can be used instead of Feature
    Given a file named "features/eating.feature" with
      """
      <keyword>: Eating
        Scenario: Eat a cucumber
          Given a step
      """
    And a file named "features/setup-steps.R" with
      """
      given("a step", function(context) {})
      """
    When I run
      """
      test("features")
      """
    Then it passes
    And the output includes "<keyword>: Eating"

    Examples:
      | keyword       |
      | Ability       |
      | Business Need |
