Feature: Fail fast
  Stop running scenarios after the first scenario that fails.
  The scenarios after it are reported as skipped, and their hooks don't run.
  With `retry`, a scenario fails only when its last attempt fails, so one that passes when it's retried doesn't stop the run.

  Background:
    Given a package
    And a file named "features/a.feature" with
      """
      Feature: A
        Scenario: Passing
          Given I have 1
          Then I get 1

        Scenario: Failing
          Given I have 1
          Then I get 2

        Scenario: After the failure
          Given I have 3
          Then I get 3
      """
    And a file named "features/b.feature" with
      """
      Feature: B
        Scenario: In the next feature file
          Given I have 4
          Then I get 4
      """
    And a file named "features/setup-steps.R" with
      """
      given("I have {int}", function(n, context) {
        context$value <- n
      })
      then("I get {int}", function(n, context) {
        expect_equal(context$value, n)
      })
      before(function(context, scenario) {
        cat("before", scenario$name, "\n")
      })
      """

  @rd
  Scenario: Scenarios after a failed scenario are skipped
    When I run
      """
      test("features", fail_fast = TRUE, stop_on_failure = FALSE)
      """
    Then the output includes "4 scenarios (1 failed, 2 skipped, 1 passed)"
    And the output includes "before Failing"
    And the output doesn't include "before After the failure"
    And the output doesn't include "before In the next feature file"

  Scenario: Scenarios skipped by fail fast say why
    When I run
      """
      test("features", fail_fast = TRUE, stop_on_failure = FALSE)
      """
    Then the scenario "After the failure" is skipped with "Reason: A previous scenario failed and `fail_fast = TRUE`."

  Scenario: A scenario without steps after a failed scenario is skipped too
    Given a file named "features/b.feature" with
      """
      Feature: B
        Scenario: Not written yet
      """
    When I run
      """
      test("features", fail_fast = TRUE, stop_on_failure = FALSE)
      """
    Then the scenario "Not written yet" is skipped with "Reason: A previous scenario failed and `fail_fast = TRUE`."
    And the output doesn't include "before Not written yet"

  Scenario: Without fail fast every scenario runs
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the output includes "4 scenarios (1 failed, 3 passed)"
    And the output includes "before In the next feature file"

  @rd
  Scenario: An undefined step fails fast in strict mode
    Given a file named "features/a.feature" with
      """
      Feature: A
        Scenario: Undefined
          Given an undefined step

        Scenario: After the undefined step
          Given I have 3
          Then I get 3
      """
    When I run
      """
      test("features", fail_fast = TRUE, stop_on_failure = FALSE)
      """
    Then the output includes "3 scenarios (1 undefined, 2 skipped)"

  Scenario: A pending step doesn't fail fast with strict = FALSE
    Given a file named "features/a.feature" with
      """
      Feature: A
        Scenario: Pending
          Given a pending step

        Scenario: After the pending step
          Given I have 3
          Then I get 3
      """
    And a file named "features/setup-pending.R" with
      """
      given("a pending step", function(context) pending())
      """
    When I run
      """
      test("features", fail_fast = TRUE, strict = FALSE)
      """
    Then the scenarios have these results:
      | scenario                 | status  |
      | Pending                  | pending |
      | After the pending step   | passed  |
      | In the next feature file | passed  |

  Scenario: A scenario that passes when it's retried doesn't stop the run
    Given a file named "features/a.feature" with
      """
      Feature: A
        Scenario: Passes the second time
          Given it fails the first time

        Scenario: After the retry
          Given I have 1
          Then I get 1
      """
    And a file named "features/b.feature" with
      """
      Feature: B
        Scenario: In the next feature file
          Given I have 4
          Then I get 4
      """
    And a file named "features/setup-flaky.R" with
      """
      given("it fails the first time", function(context) {
        if (!file.exists("failed-once")) {
          file.create("failed-once")
          stop("Failed the first time")
        }
      })
      """
    When I run
      """
      test("features", fail_fast = TRUE, retry = 1, stop_on_failure = FALSE)
      """
    Then the scenarios have these results:
      | scenario                 | status | attempts |
      | Passes the second time   | passed | 2        |
      | After the retry          | passed | 1        |
      | In the next feature file | passed | 1        |
