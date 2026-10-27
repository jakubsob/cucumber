Feature: Running scenarios by line
  Run only the scenarios at given lines of a feature file, like `test(features = "addition.feature:2")`.
  Each line is the line of a Scenario or an Examples row.

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
  Scenario: Only the scenario at the line is run
    When I run
      """
      test("features", features = "addition.feature:6")
      """
    Then only these scenarios ran:
      | scenario           |
      | Adding big numbers |

  Scenario: The line of a step runs no scenario
    When I run
      """
      test("features", features = "addition.feature:3")
      """
    Then no scenario ran

  Scenario: An absolute path can be given
    When I run
      """
      test("features", features = fs::path_abs("features/addition.feature:6"))
      """
    Then only these scenarios ran:
      | scenario           |
      | Adding big numbers |

  @rd
  Scenario: Several lines and several files can be given
    When I run
      """
      test("features", features = c("addition.feature:2:6", "subtraction.feature:2"))
      """
    Then only these scenarios ran:
      | scenario                  |
      | Adding small numbers      |
      | Adding big numbers        |
      | Subtracting small numbers |

  @rd
  Scenario: The line of a Scenario Outline runs all its examples
    When I run
      """
      test("features", features = "addition.feature:10")
      """
    Then only these scenarios ran:
      | scenario |
      | Adding 2 |
      | Adding 3 |

  @rd
  Scenario: The line of an example row runs only that example
    When I run
      """
      test("features", features = "addition.feature:17")
      """
    Then only these scenarios ran:
      | scenario |
      | Adding 3 |
