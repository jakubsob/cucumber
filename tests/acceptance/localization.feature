Feature: Localization
  A `# language:` line at the top of a feature file sets the language of its keywords,
  like in the official Gherkin parser. Every language from gherkin-languages.json is supported.
  Step definitions don't change, because steps are matched without their keyword.

  Scenario: A feature file written in French
    Given a package
    And a file named "features/addition.feature" with
      """
      # language: fr
      Fonctionnalité: Addition
        Contexte:
          Soit I have 1

        Scénario: Adding one
          Quand I add 1
          Alors I should have 2

        Plan du scénario: Adding more
          Quand I add <n>
          Et I add <n>
          Alors I should have <total>

          Exemples:
            | n | total |
            | 2 | 5     |
      """
    And a file named "features/setup-steps.R" with
      """
      given("I have {int}", function(n, context) {
        context$n <- n
      })
      when("I add {int}", function(n, context) {
        context$n <- context$n + n
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

  Scenario: An unknown language is a parse error
    Given a package
    And a file named "features/unknown.feature" with
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
