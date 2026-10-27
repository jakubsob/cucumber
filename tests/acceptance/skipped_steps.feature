Feature: Skipped steps
  Call `skip_scenario()` in a step or a `before()` hook to skip the rest of the scenario,
  for example when a service it needs is down. The scenario is reported as skipped with its reason,
  and after hooks still run and get `"skipped"` as its status.
  In an `after()` hook, it skips only that hook, and the scenario is skipped unless it failed.
  In a `before_all()` hook, it skips every scenario of the run. Calling it in a `before_step()`, `after_step()`
  or `after_all()` hook is an error of the hook. `testthat::skip()` does the same.

  Background:
    Given a package

  @rd
  Scenario: A step skips the scenario with skip_scenario()
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Sync the basket
          Given an empty basket
          When I sync the basket
          Then the basket is synced
      """
    And a file named "features/setup-steps.R" with
      """
      after(function(context, scenario) cat("after:", scenario$name, scenario$status, "\n"))
      given("an empty basket", function(context) {})
      when("I sync the basket", function(context) skip_scenario("the API is down"))
      then("the basket is synced", function(context) stop("this step must not execute"))
      """
    When I run
      """
      test("features")
      """
    Then the scenario "Sync the basket" is skipped with "Reason: the API is down"
    And the output includes "after: Sync the basket skipped"
    And the steps have these results:
      | step                      | status  |
      | Given an empty basket     | passed  |
      | When I sync the basket    | skipped |
      | Then the basket is synced | skipped |

  @rd
  Scenario: A before hook skips the scenario with skip_scenario()
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        @api
        Scenario: Sync the basket
          Given an empty basket
          When I sync the basket

        Scenario: Add an item
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      before(function(context, scenario) skip_scenario("the API is down"), tags = "@api")
      before(function(context, scenario) cat("this hook must not run for", scenario$name, "\n"), tags = "@api")
      after(function(context, scenario) cat("after:", scenario$name, scenario$status, "\n"))
      given("an empty basket", function(context) {})
      when("I sync the basket", function(context) stop("this step must not execute"))
      """
    When I run
      """
      test("features")
      """
    Then the scenario "Sync the basket" is skipped with "Reason: the API is down"
    And the output includes
      """
      after: Sync the basket skipped
      after: Add an item passed
      """
    And the output doesn't include "this hook must not run"
    And the steps and hooks have these results:
      | scenario        | step                   | status  |
      | Sync the basket | Before                 | skipped |
      | Sync the basket | Before                 | skipped |
      | Sync the basket | Given an empty basket  | skipped |
      | Sync the basket | When I sync the basket | skipped |
      | Sync the basket | After                  | passed  |
      | Add an item     | Given an empty basket  | passed  |
      | Add an item     | After                  | passed  |

  Scenario: Undefined and ambiguous steps after a skipped step are skipped
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Sync the basket
          When I sync the basket
          Then the basket is synced
          And the basket is synced twice
      """
    And a file named "features/setup-steps.R" with
      """
      when("I sync the basket", function(context) skip_scenario("the API is down"))
      then("the basket is synced {word}", function(word, context) {})
      then("the basket is synced {}", function(x, context) {})
      """
    When I run
      """
      test("features")
      """
    Then the scenario "Sync the basket" is skipped with "Reason: the API is down"
    And the steps have these results:
      | step                           | status  |
      | When I sync the basket         | skipped |
      | Then the basket is synced      | skipped |
      | And the basket is synced twice | skipped |

  Scenario: Undefined and ambiguous steps after a before hook that skipped the scenario are skipped
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Sync the basket
          Then the basket is synced
          And the basket is synced twice
      """
    And a file named "features/setup-steps.R" with
      """
      before(function(context, scenario) skip_scenario("the API is down"))
      then("the basket is synced {word}", function(word, context) {})
      then("the basket is synced {}", function(x, context) {})
      """
    When I run
      """
      test("features")
      """
    Then the scenario "Sync the basket" is skipped with "Reason: the API is down"
    And the steps and hooks have these results:
      | step                           | status  |
      | Before                         | skipped |
      | Then the basket is synced      | skipped |
      | And the basket is synced twice | skipped |

  @rd
  Scenario: skip_scenario() in an after hook skips the hook, and the after hooks after it still run
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      after(function(context, scenario) cat("this hook still runs\n"))
      after(function(context, scenario) skip_scenario("too late"))
      given("an empty basket", function(context) {})
      """
    When I run
      """
      test("features")
      """
    Then the scenario "Add an item" is skipped with "Reason: too late"
    And the output includes "this hook still runs"

  Scenario: skip_scenario() in a before all hook skips every scenario
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Sync the basket
          Given an empty basket

        Scenario: Add an item
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      before_all(function() skip_scenario("the API is down"))
      given("an empty basket", function(context) {})
      """
    When I run
      """
      test("features")
      """
    Then the scenarios have these results:
      | scenario        | status  |
      | Sync the basket | skipped |
      | Add an item     | skipped |
    And the results are skipped with "the API is down"

  Rule: testthat::skip() also skips the scenario

    Scenario: testthat::skip() in a step skips the scenario
      Given a file named "features/basket.feature" with
        """
        Feature: Basket
          Scenario: Sync the basket
            When I sync the basket
            Then the basket is synced
        """
      And a file named "features/setup-steps.R" with
        """
        after(function(context, scenario) cat("after:", scenario$name, scenario$status, "\n"))
        when("I sync the basket", function(context) testthat::skip("the API is down"))
        then("the basket is synced", function(context) stop("this step must not execute"))
        """
      When I run
        """
        test("features")
        """
      Then the scenario "Sync the basket" is skipped with "Reason: the API is down"
      And the output includes "after: Sync the basket skipped"
      And the steps have these results:
        | step                      | status  |
        | When I sync the basket    | skipped |
        | Then the basket is synced | skipped |

    Scenario: testthat::skip() in a before hook skips the scenario
      Given a file named "features/basket.feature" with
        """
        Feature: Basket
          Scenario: Sync the basket
            When I sync the basket
        """
      And a file named "features/setup-steps.R" with
        """
        before(function(context, scenario) testthat::skip("the API is down"))
        after(function(context, scenario) cat("after:", scenario$name, scenario$status, "\n"))
        when("I sync the basket", function(context) stop("this step must not execute"))
        """
      When I run
        """
        test("features")
        """
      Then the scenario "Sync the basket" is skipped with "Reason: the API is down"
      And the output includes "after: Sync the basket skipped"
      And the steps and hooks have these results:
        | step                   | status  |
        | Before                 | skipped |
        | When I sync the basket | skipped |
        | After                  | passed  |

    Scenario: testthat::skip() in an after hook skips the hook
      Given a file named "features/basket.feature" with
        """
        Feature: Basket
          Scenario: Add an item
            Given an empty basket
        """
      And a file named "features/setup-steps.R" with
        """
        after(function(context, scenario) cat("this hook still runs\n"))
        after(function(context, scenario) testthat::skip("too late"))
        given("an empty basket", function(context) {})
        """
      When I run
        """
        test("features")
        """
      Then the scenario "Add an item" is skipped with "Reason: too late"
      And the output includes "this hook still runs"
