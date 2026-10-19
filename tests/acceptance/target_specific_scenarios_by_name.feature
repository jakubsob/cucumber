Feature: Running scenarios by name
  Run only the scenarios whose name matches a regular expression, like `test(name = "^Adding")`.

  Background:
    Given a package
    And a file named "features/addition.feature" with
      """
      Feature: Addition
        Scenario: Adding small numbers
          Given I have 1
          Then I get 1

        Scenario: Adding big numbers
          Given I have 1000
          Then I get 1000

        Scenario Outline: Adding <n>
          Given I have <n>
          Then I get <n>

          Examples:
            | n |
            | 2 |
            | 3 |
      """
    And a file named "features/subtraction.feature" with
      """
      Feature: Subtraction
        Scenario: Subtracting small numbers
          Given I have 1
          Then I get 1
      """
    And a file named "features/setup-steps.R" with
      """
      given("I have {int}", function(n, context) {
        context$value <- n
      })
      then("I get {int}", function(n, context) {
        expect_equal(context$value, n)
      })
      """

  @rd
  Scenario: Only the scenarios whose name matches are run
    When I run
      """
      test("features", name = "small")
      """
    Then only these scenarios ran:
      | scenario                  |
      | Adding small numbers      |
      | Subtracting small numbers |

  Scenario: Features without matching scenarios aren't reported
    When I run
      """
      test("features", name = "big")
      """
    Then only "Addition" was run
    And the output includes "| Addition"
    And the output doesn't include "Subtraction"

  Scenario: A scenario runs if its name matches any of the regular expressions
    When I run
      """
      test("features", name = c("^Adding big", "^Subtracting"))
      """
    Then only these scenarios ran:
      | scenario                  |
      | Adding big numbers        |
      | Subtracting small numbers |

  @rd
  Scenario: The name of an outline's example has its placeholders replaced
    When I run
      """
      test("features", name = "Adding 3")
      """
    Then only these scenarios ran:
      | scenario |
      | Adding 3 |
