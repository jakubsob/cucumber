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
    Then the errors are
      """
      [error]
      Error: Can't parse feature files
      x Parse error in "broken.feature" (4:5): expected: #EOF, #TableRow, #DocStringSeparator, #StepLine, #TagLine, #ExamplesLine, #ScenarioLine, #RuleLine, #Comment, #Empty, got 'this line is not a step'
      x Parse error in "broken.feature" (9:7): inconsistent cell count within the table
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
    Then the errors are
      """
      [error]
      Error: Can't parse feature files
      x Parse error in "unknown.feature" (1:1): Language not supported: xx
      """

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
    Then the errors are
      """
      [error]
      Error: Can't parse feature files
      x Parse error in "tagged.feature" (1:1): A tag may not contain whitespace
      x Parse error in "tagged.feature" (1:1): expected: #EOF, #Language, #TagLine, #FeatureLine, #Comment, #Empty, got '@work in progress'
      """

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
    Then the errors are
      """
      [error]
      Error: Can't parse feature files
      x Parse error in "tagged.feature" (2:0): unexpected end of file, expected: #TagLine, #FeatureLine, #Comment, #Empty
      """

  Scenario: Parsing stops at the 11th error
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
    Then the errors are
      """
      [error]
      Error: Can't parse feature files
      x Parse error in "broken.feature" (4:5): expected: #EOF, #TableRow, #DocStringSeparator, #StepLine, #TagLine, #ExamplesLine, #ScenarioLine, #RuleLine, #Comment, #Empty, got 'junk 1'
      x Parse error in "broken.feature" (5:5): expected: #EOF, #TableRow, #DocStringSeparator, #StepLine, #TagLine, #ExamplesLine, #ScenarioLine, #RuleLine, #Comment, #Empty, got 'junk 2'
      x Parse error in "broken.feature" (6:5): expected: #EOF, #TableRow, #DocStringSeparator, #StepLine, #TagLine, #ExamplesLine, #ScenarioLine, #RuleLine, #Comment, #Empty, got 'junk 3'
      x Parse error in "broken.feature" (7:5): expected: #EOF, #TableRow, #DocStringSeparator, #StepLine, #TagLine, #ExamplesLine, #ScenarioLine, #RuleLine, #Comment, #Empty, got 'junk 4'
      x Parse error in "broken.feature" (8:5): expected: #EOF, #TableRow, #DocStringSeparator, #StepLine, #TagLine, #ExamplesLine, #ScenarioLine, #RuleLine, #Comment, #Empty, got 'junk 5'
      x Parse error in "broken.feature" (9:5): expected: #EOF, #TableRow, #DocStringSeparator, #StepLine, #TagLine, #ExamplesLine, #ScenarioLine, #RuleLine, #Comment, #Empty, got 'junk 6'
      x Parse error in "broken.feature" (10:5): expected: #EOF, #TableRow, #DocStringSeparator, #StepLine, #TagLine, #ExamplesLine, #ScenarioLine, #RuleLine, #Comment, #Empty, got 'junk 7'
      x Parse error in "broken.feature" (11:5): expected: #EOF, #TableRow, #DocStringSeparator, #StepLine, #TagLine, #ExamplesLine, #ScenarioLine, #RuleLine, #Comment, #Empty, got 'junk 8'
      x Parse error in "broken.feature" (12:5): expected: #EOF, #TableRow, #DocStringSeparator, #StepLine, #TagLine, #ExamplesLine, #ScenarioLine, #RuleLine, #Comment, #Empty, got 'junk 9'
      x Parse error in "broken.feature" (13:5): expected: #EOF, #TableRow, #DocStringSeparator, #StepLine, #TagLine, #ExamplesLine, #ScenarioLine, #RuleLine, #Comment, #Empty, got 'junk 10'
      x Parse error in "broken.feature" (14:5): expected: #EOF, #TableRow, #DocStringSeparator, #StepLine, #TagLine, #ExamplesLine, #ScenarioLine, #RuleLine, #Comment, #Empty, got 'junk 11'
      """

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
    Then no scenario ran
    And the errors are
      """
      [error]
      Error: Can't parse feature files
      x Parse error in "a.feature" (1:1): expected: #EOF, #Language, #TagLine, #FeatureLine, #Comment, #Empty, got 'Parse Error'
      x Parse error in "c.feature" (1:1): expected: #EOF, #Language, #TagLine, #FeatureLine, #Comment, #Empty, got 'Parse Error'
      """
