Feature: Dry run
  `test(dry_run = TRUE)` matches every step to a step definition, but runs neither steps nor hooks.
  Use it to find undefined and ambiguous steps without running the scenarios.
  Undefined and ambiguous steps are reported, but they don't fail a dry run: a scenario with one is skipped.

  Scenario: A dry run doesn't run steps or hooks
    Given a package
    And a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
          When I add an item
      """
    And a file named "features/setup-steps.R" with
      """
      before_all(function() stop("hooks must not run"))
      before(function(context, scenario) stop("hooks must not run"))
      before_step(function(context, step) stop("hooks must not run"))
      after_all(function() stop("hooks must not run"))
      given("an empty basket", function(context) {
        stop("steps must not run")
      })
      when("I add an item", function(context) {
        stop("steps must not run")
      })
      """
    When I run
      """
      test("features", dry_run = TRUE)
      """
    Then it has 0 errors
    And it has 0 failed
    And the steps and hooks have these results:
      | step                  | status  |
      | Given an empty basket | skipped |
      | When I add an item    | skipped |

  Scenario: A dry run reports undefined steps without failing
    Given a package
    And a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
          When I add an item
      """
    And a file named "features/setup-steps.R" with
      """
      given("an empty basket", function(context) {
        stop("steps must not run")
      })
      """
    When I run
      """
      test("features", dry_run = TRUE)
      """
    Then it has 0 failed
    And it has 1 skipped
    And the steps have these results:
      | step                  | status    |
      | Given an empty basket | skipped   |
      | When I add an item    | undefined |
    And the output includes
      """
      when("I add an item", function(context) {
      """

  Scenario: A dry run reports ambiguous steps without failing
    Given a package
    And a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          When I add an item
      """
    And a file named "features/setup-steps.R" with
      """
      when("I add an item", function(context) {})
      when("I add an {word}", function(thing, context) {})
      """
    When I run
      """
      test("features", dry_run = TRUE)
      """
    Then it has 0 failed
    And it has 1 skipped
    And the steps have these results:
      | step               | status    |
      | When I add an item | ambiguous |

  Scenario: A step that would be pending is skipped in a dry run
    Given a package
    And a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          When I add an item
      """
    And a file named "features/setup-steps.R" with
      """
      when("I add an item", function(context) pending())
      """
    When I run
      """
      test("features", dry_run = TRUE)
      """
    Then it has 0 failed
    And it has 1 skipped
    And the steps have these results:
      | step               | status  |
      | When I add an item | skipped |
