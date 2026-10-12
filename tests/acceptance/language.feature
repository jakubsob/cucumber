Feature: Language
  A `# language:` line at the top of a feature file sets the language of its keywords,
  like in the official Gherkin parser. The languages are the ones in the official gherkin-languages.json.
  Step definitions don't change, because steps are matched without their keyword.

  Background:
    Given a package

  Scenario: A feature file written in French
    Given a file named "features/addition.feature" with
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
