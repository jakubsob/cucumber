Feature: Pending steps

  Scenario: A pending step is reported as skipped, not failed
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/pending.feature" with
      """
      Feature: Pending
        Scenario: Not yet implemented
          Given a step that is pending
      """
    And a file named "features/setup-steps.R" with
      """
      given("a step that is pending", function(context) {
        pending("not yet implemented")
      })
      """
    When I run
      """
      test("features")
      """
    Then it has 1 skipped

  Scenario: Steps after a pending step do not run
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/pending.feature" with
      """
      Feature: Pending
        Scenario: Skips the rest
          Given a step that is pending
          Then this step should not run
      """
    And a file named "features/setup-steps.R" with
      """
      given("a step that is pending", function(context) {
        pending()
      })
      then("this step should not run", function(context) {
        stop("this step must not execute")
      })
      """
    When I run
      """
      test("features")
      """
    Then it has 1 skipped
    Then it has 0 errors

  Scenario: A non-pending scenario is not affected
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/mixed.feature" with
      """
      Feature: Mixed
        Scenario: Implemented
          Given I have 1
          Then I get 1

        Scenario: Not yet implemented
          Given a step that is pending
      """
    And a file named "features/setup-steps.R" with
      """
      given("I have {int}", function(n, context) {
        context$value <- n
      })
      then("I get {int}", function(n, context) {
        expect_equal(context$value, n)
      })
      given("a step that is pending", function(context) {
        pending()
      })
      """
    When I run
      """
      test("features")
      """
    Then it has 1 passed
    And it has 1 skipped
