Feature: Ambiguous steps
  A step must match exactly one step definition.
  When it matches more than one, the step is reported as ambiguous, listing
  every matching definition, and the scenario fails.

  @rd
  Scenario: A step matching two definitions fails with both definitions listed
    Given a package
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
    Then the steps have these results:
      | step                     | status    |
      | Given the user is "John" | ambiguous |
    And the errors are
      """
      [failure] Scenario: Name a user
      Multiple step definitions match: "the user is "John""
      i Make the step match only one of:
      * "the user is {}" (setup-steps.R:1)
      * "the user is {string}" (setup-steps.R:4)
      """

  Scenario: The same step defined twice is ambiguous
    Given a package
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
    Then the errors are
      """
      [failure] Scenario: Add an item
      Multiple step definitions match: "I add an item"
      i Make the step match only one of:
      * "I add an item" (setup-steps.R:1)
      * "I add an item" (setup-steps.R:4)
      """

  @rd
  Scenario: Steps are matched without their keyword
    A Given and a Then step with the same text match the same step definitions,
    so choose words that tell them apart, like "my account has a balance of £430"
    and "my account should have a balance of £430".

    Given a package
    And a file named "features/account.feature" with
      """
      Feature: Account
        Scenario: Withdraw
          Given there is money in my account
      """
    And a file named "features/setup-steps.R" with
      """
      given("there is money in my account", function(context) {})
      then("there is money in my account", function(context) {})
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the steps have these results:
      | step                               | status    |
      | Given there is money in my account | ambiguous |
    And the errors are
      """
      [failure] Scenario: Withdraw
      Multiple step definitions match: "there is money in my account"
      i Make the step match only one of:
      * "there is money in my account" (setup-steps.R:1)
      * "there is money in my account" (setup-steps.R:2)
      """

  Scenario: {int} and {float} definitions are ambiguous for an integer
    Given a package
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
    Then the errors are
      """
      [failure] Scenario: Count cucumbers
      Multiple step definitions match: "there are 12 cucumbers"
      i Make the step match only one of:
      * "there are {int} cucumbers" (setup-steps.R:1)
      * "there are {float} cucumbers" (setup-steps.R:4)
      """
