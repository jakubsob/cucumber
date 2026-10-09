Feature: Pending steps
  Call `pending()` in a step to mark it as not implemented yet.
  The step is reported as pending, and the steps after it are skipped.
  A pending scenario fails the run, unless it's run with `strict = FALSE`.

  Background:
    Given a package

  Scenario: A pending step fails the scenario
    Given a file named "features/pending.feature" with
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
    Given a file named "features/pending.feature" with
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

  Scenario Outline: A before hook makes the scenario pending with pending(), strict = <strict>
    A pending scenario fails the run only in strict mode, like a pending step.

    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Sync the basket
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      before(function(context, scenario) pending("the API client isn't written yet"))
      after(function(context, scenario) cat("after:", scenario$name, scenario$status, "\n"))
      given("an empty basket", function(context) stop("this step must not execute"))
      """
    When I run
      """
      test("features", strict = <strict>, stop_on_failure = FALSE)
      """
    Then the scenario "Sync the basket" is <outcome> with "<message>"
    And the output includes
      """
      Scenario: Sync the basket
        - Given an empty basket
      after: Sync the basket pending
      """
    And the output includes
      """
      1 scenario (1 pending)
      1 step (1 skipped)
      """

    Examples:
      | strict | outcome | message                                                   |
      | TRUE   | failed  | Hook is pending: the API client isn't written yet         |
      | FALSE  | skipped | Reason: Hook is pending: the API client isn't written yet |
