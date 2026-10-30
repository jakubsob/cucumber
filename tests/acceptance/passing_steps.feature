@rd
Feature: Passing steps
  A step passes when its step definition returns without an error.
  A scenario passes when all its steps pass, even if they have no expectations.
  testthat reports it as passed too, not skipped like an empty `test_that()` test.

  Background:
    Given a package

  Scenario: A scenario whose steps pass without expectations passes
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
          When I add an item
      """
    And a file named "features/setup-steps.R" with
      """
      given("an empty basket", function(context) {
        context$basket <- list()
      })
      when("I add an item", function(context) {
        context$basket <- c(context$basket, "item")
      })
      """
    When I run
      """
      test("features", reporter = NULL)
      """
    Then it passes

  Scenario: Steps run one by one, in the order they are written
    Given a file named "features/sum.feature" with
      """
      Feature: Sum
        Scenario: Sum should work for 2 numbers
          Given I have 1
          And I have 2
          When I add them
          Then I get 3

        Scenario: Sum should work for 3 numbers
          Given I have 1
          And I have 2
          But I have 3
          When I add them
          Then I get 6
      """
    And a file named "features/setup-steps.R" with
      """
      given("I have {int}", function(int, context) {
        print("given")
        context$numbers <- c(context$numbers, int)
      })

      when("I add them", function(context) {
        print("when")
        context$result <- sum(context$numbers)
      })

      then("I get {int}", function(int, context) {
        print("then")
        expect_equal(context$result, int)
      })
      """
    When I run
      """
      test("features", reporter = NULL)
      """
    Then the output includes
      """
      [1] "given"
      [1] "given"
      [1] "when"
      [1] "then"
      [1] "given"
      [1] "given"
      [1] "given"
      [1] "when"
      [1] "then"
      """

  Scenario: testthat reports a scenario without expectations or steps as passed
    Given a file named "tests/testthat/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
          When I add an item

        Scenario: Not written yet
      """
    And a file named "tests/testthat/setup-steps.R" with
      """
      given("an empty basket", function(context) {
        context$basket <- list()
      })
      when("I add an item", function(context) {
        context$basket <- c(context$basket, "item")
      })
      """
    And a file named "tests/testthat/test-acceptance.R" with
      """
      run()
      """
    When I run
      """
      testthat::test_local(reporter = "silent")
      """
    Then it passes
    And only these scenarios ran:
      | scenario        |
      | Add an item     |
      | Not written yet |
