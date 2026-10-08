Feature: Fail fast
  Stop running scenarios after the first scenario that fails.
  The scenarios after it are reported as skipped, and their hooks don't run.

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

  Scenario: Scenarios after a failed scenario are skipped
    When I run
      """
      test("features", fail_fast = TRUE, stop_on_failure = FALSE)
      """
    Then the output includes "4 scenarios (1 failed, 2 skipped, 1 passed)"
    And the output includes "before Failing"
    And the output doesn't include "before After the failure"
    And the output doesn't include "before In the next feature file"

  Scenario: Without fail fast every scenario runs
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the output includes "4 scenarios (1 failed, 3 passed)"
    And the output includes "before In the next feature file"

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
