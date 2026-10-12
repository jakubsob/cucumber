Feature: Gherkin parse failure
  A feature file that isn't valid Gherkin fails with every error and its line:column.
  Every feature file is parsed before anything runs,
  so if any of them can't be parsed, no scenario runs.

  Background:
    Given a package

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

  Scenario: No scenario runs when a feature file fails to parse, and every parse error is reported
    Given a file named "features/a.feature" with
      """
      Parse Error
      """
    And a file named "features/b.feature" with
      """
      Feature: Valid
        Scenario: A step
          Given a step
      """
    And a file named "features/c.feature" with
      """
      Parse Error
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
    And it has 0 passed
    And the error message includes "Parse error in \"a.feature\" (1:1)"
    And the error message includes "Parse error in \"c.feature\" (1:1)"
