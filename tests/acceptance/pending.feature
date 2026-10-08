Feature: Pending steps
  A step that calls `pending()` is reported as pending, and the steps after it are skipped.
  A pending step fails the run, unless it's run with `strict = FALSE`.

  Scenario: A pending step fails the scenario
    Given a package
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
      test("features", stop_on_failure = FALSE)
      """
    Then it has 1 failed
    And the error message includes
      """
      Step "a step that is pending" is pending: not yet implemented
      """
    And the output includes
      """
      P Given a step that is pending
      """
    And the output includes
      """
      1 scenario (1 pending)
      1 step (1 pending)
      """

  Scenario: Steps after a pending step are skipped
    Given a package
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
      test("features", stop_on_failure = FALSE)
      """
    Then it has 1 failed
    And it has 0 errors
    And the output includes
      """
      P Given a step that is pending
      """
    And the output includes
      """
      - Then this step should not run
      """

  Scenario: A pending step skips the scenario when not strict
    Given a package
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
      test("features", strict = FALSE)
      """
    Then it has 1 passed
    And it has 1 skipped
    And it has 0 failed
