Feature: Finding feature files
  Feature files are found in the given directory and its subdirectories,
  like Cucumber's default `features/**/*.feature`.

  Scenario: Feature files in subdirectories are run
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/addition.feature" with
      """
      Feature: Addition
        Scenario: Adding
          Given I have 1
          Then I get 1
      """
    And a file named "features/math/subtraction.feature" with
      """
      Feature: Subtraction
        Scenario: Subtracting
          Given I have 2
          Then I get 2
      """
    And a file named "features/math/advanced/division.feature" with
      """
      Feature: Division
        Scenario: Dividing
          Given I have 3
          Then I get 3
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
    When I run
      """
      test("features")
      """
    Then it has 3 passed
    And it ran "Scenario: Subtracting"
    And it ran "Scenario: Dividing"
