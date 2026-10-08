Feature: Regular expressions
  A step description that starts with "^", ends with "$" or is surrounded by "/"
  is a regular expression instead of a Cucumber Expression.
  The text of each capture group is passed to the step.

  Scenario: Capture groups are passed to the step
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Colours
          Given I have a red cucumber
          And I have a green cucumber
          Then I have 2 cucumbers
      """
    And a file named "features/setup-steps.R" with
      """
      given("^I have a (red|green) cucumber$", function(colour, context) {
        context$colours <- c(context$colours, colour)
      })
      then("/I have (\\d+) cucumbers/", function(n, context) {
        expect_identical(n, 2L)
        expect_equal(context$colours, c("red", "green"))
      })
      """
    When I run
      """
      test("features")
      """
    Then it passes

  Scenario: A capture group that doesn't match passes NA
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/vegetables.feature" with
      """
      Feature: Vegetables
        Scenario: Optional groups
          Given a cucumber and a carrot
          Then the vegetables are cucumber and carrot
      """
    And a file named "features/setup-steps.R" with
      """
      given("^a (.*?)(?: and a (.*?))?(?: and a (.*?))?$", function(first, second, third, context) {
        context$vegetables <- c(first, second, third)
      })
      then("^the vegetables are (.*)$", function(names, context) {
        expect_equal(context$vegetables, c("cucumber", "carrot", NA))
      })
      """
    When I run
      """
      test("features")
      """
    Then it passes
