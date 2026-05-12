Feature: Background

  Scenario: Background steps run before each scenario
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/background.feature" with
      """
      Feature: Background example
        Background:
          Given the value is 10

        Scenario: First scenario
          Then I get 10

        Scenario: Second scenario
          Then I get 10
      """
    And a file named "features/setup-steps.R" with
      """
      given("the value is {int}", function(n, context) {
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
    Then it passes
    And it has 2 passed

  Scenario: Background steps are independent per scenario
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/background.feature" with
      """
      Feature: Background isolation
        Background:
          Given the value is 0

        Scenario: Increment once
          When I add 1
          Then I get 1

        Scenario: Increment twice
          When I add 1
          And I add 1
          Then I get 2
      """
    And a file named "features/setup-steps.R" with
      """
      given("the value is {int}", function(n, context) {
        context$value <- n
      })
      when("I add {int}", function(n, context) {
        context$value <- context$value + n
      })
      then("I get {int}", function(n, context) {
        expect_equal(context$value, n)
      })
      """
    When I run
      """
      test("features")
      """
    Then it passes
    And it has 2 passed

  Scenario: A failing background step marks the scenario as failed
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/background.feature" with
      """
      Feature: Failing background
        Background:
          Given a step that always fails

        Scenario: Should fail
          Then I get 1
      """
    And a file named "features/setup-steps.R" with
      """
      given("a step that always fails", function(context) {
        stop("background failure")
      })
      then("I get {int}", function(n, context) {
        expect_equal(context$value, n)
      })
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then it has 1 errors
