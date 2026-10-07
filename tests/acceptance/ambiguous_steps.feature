Feature: Ambiguous steps
  A step must match exactly one step definition.
  When it matches more than one, the step is reported as ambiguous, listing
  every matching definition, and the scenario fails.

  Scenario: A step matching two definitions fails with both definitions listed
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/user.feature" with
      """
      Feature: User
        Scenario: Name a user
          Given the user is "John"
      """
    And a file named "features/setup-steps.R" with
      """
      given("the user is {}", function(user, context) {
        context$user <- user
      })
      given("the user is {string}", function(user, context) {
        context$user <- user
      })
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then it has 1 failed
    And the error message includes
      """
      Multiple step definitions match: "the user is "John""
      """
    And the error message includes
      """
      "the user is {}" (setup-steps.R:1)
      """
    And the error message includes
      """
      "the user is {string}" (setup-steps.R:4)
      """

  Scenario: The same step defined twice is ambiguous
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          When I add an item
      """
    And a file named "features/setup-steps.R" with
      """
      when("I add an item", function(context) {
        context$items <- 1
      })
      when("I add an item", function(context) {
        context$items <- 2
      })
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then it has 1 failed
    And the error message includes
      """
      Multiple step definitions match: "I add an item"
      """

  Scenario: {int} and {float} definitions are ambiguous for an integer
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Count cucumbers
          Given there are 12 cucumbers
      """
    And a file named "features/setup-steps.R" with
      """
      given("there are {int} cucumbers", function(n, context) {
        context$cucumbers <- n
      })
      given("there are {float} cucumbers", function(n, context) {
        context$cucumbers <- n
      })
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then it has 1 failed
    And the error message includes
      """
      Multiple step definitions match: "there are 12 cucumbers"
      """
