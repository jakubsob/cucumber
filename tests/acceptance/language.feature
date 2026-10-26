Feature: Language
  A `# language:` line at the top of a feature file sets the language of its keywords,
  like in the official Gherkin parser. The languages are the ones in the official gherkin-languages.json.
  Step definitions don't change, because steps are matched without their keyword.
  The `cucumber.language` option sets the language of feature files without a `# language:` line.

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
    Then the scenarios have these results:
      | scenario    | status |
      | Adding one  | passed |
      | Adding more | passed |

  @rd
  Scenario: The cucumber.language option sets the language of feature files without a language line
    Given a file named "features/addition.feature" with
      """
      Fonctionnalité: Addition
        Scénario: Adding one
          Soit I have 1
          Quand I add 1
          Alors I should have 2
      """
    And a file named "features/subtraction.feature" with
      """
      # language: en
      Feature: Subtraction
        Scenario: Taking one
          Given I have 2
          When I add -1
          Then I should have 1
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
      withr::with_options(list(cucumber.language = "fr"), test("features"))
      """
    Then the scenarios have these results:
      | scenario   | status |
      | Adding one | passed |
      | Taking one | passed |

  Scenario: An unknown cucumber.language option is an error
    Given a file named "features/addition.feature" with
      """
      Feature: Addition
      """
    When I run it and it fails
      """
      withr::with_options(list(cucumber.language = "klingon"), test("features"))
      """
    Then it fails with
      """
      Error:
      ! Test failures.
      Caused by error:
      ! Language not supported: klingon
      i The `cucumber.language` option must be a language of Gherkin, like "fr".
      """

  Scenario: A cucumber.language option that isn't a language code is an error
    Given a file named "features/addition.feature" with
      """
      Feature: Addition
      """
    When I run it and it fails
      """
      withr::with_options(list(cucumber.language = c("fr", "de")), test("features"))
      """
    Then it fails with
      """
      Error:
      ! Test failures.
      Caused by error:
      ! The `cucumber.language` option must be a language code, like "fr".
      """
