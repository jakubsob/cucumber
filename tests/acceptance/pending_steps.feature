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
    And the steps have these results:
      | step                         | status  |
      | Given a step that is pending | pending |

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
    And the steps have these results:
      | step                          | status  |
      | Given a step that is pending  | pending |
      | Then this step should not run | skipped |

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
    And the output includes "after: Sync the basket pending"
    And the steps and hooks have these results:
      | step                  | status  |
      | Before                | pending |
      | Given an empty basket | skipped |
      | After                 | passed  |

    Examples:
      | strict | outcome | message                                                   |
      | TRUE   | failed  | Hook is pending: the API client isn't written yet         |
      | FALSE  | skipped | Reason: Hook is pending: the API client isn't written yet |

  Scenario Outline: pending() in <hook>() makes the scenario pending, strict = <strict>
    A pending step hook makes its step pending. A pending after hook makes the scenario pending.

    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Sync the basket
          Given an empty basket
          Then the basket is synced
      """
    And a file named "features/setup-steps.R" with
      """
      <hook>(function(context, <argument>) pending("the API client isn't written yet"))
      given("an empty basket", function(context) {})
      then("the basket is synced", function(context) {})
      """
    When I run
      """
      test("features", strict = <strict>, stop_on_failure = FALSE)
      """
    Then the scenario "Sync the basket" is <outcome> with "<message>"
    And the scenarios have these results:
      | scenario        | status  |
      | Sync the basket | pending |
    And the steps have these results:
      | step                      | status   |
      | Given an empty basket     | <given>  |
      | Then the basket is synced | <then>   |

    Examples:
      | hook        | argument | strict | outcome | message                                                   | given   | then    |
      | before_step | step     | TRUE   | failed  | Hook is pending: the API client isn't written yet         | pending | skipped |
      | after_step  | step     | TRUE   | failed  | Hook is pending: the API client isn't written yet         | pending | skipped |
      | after       | scenario | TRUE   | failed  | Hook is pending: the API client isn't written yet         | passed  | passed  |
      | before_step | step     | FALSE  | skipped | Reason: Hook is pending: the API client isn't written yet | pending | skipped |
      | after_step  | step     | FALSE  | skipped | Reason: Hook is pending: the API client isn't written yet | pending | skipped |
      | after       | scenario | FALSE  | skipped | Reason: Hook is pending: the API client isn't written yet | passed  | passed  |
