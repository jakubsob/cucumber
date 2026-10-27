@rd
Feature: Snippets reporter
  `CucumberSnippetsReporter` prints only the snippets of the step definitions that undefined steps
  need, like Cucumber's `snippets` formatter, to paste them into a setup file. A step undefined in
  several scenarios gets one snippet.

  Background:
    Given a package
    And a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add cucumbers
          Given an empty basket
          When I add 5 cucumbers
          Then the basket is full

        Scenario: Empty the basket
          Given an empty basket
          When I empty the basket
      """
    And a file named "features/setup-steps.R" with
      """
      given("an empty basket", function(context) {})
      """

  Scenario: Only the snippets of undefined steps are printed
    When I run
      """
      test("features", reporter = CucumberSnippetsReporter$new(), stop_on_failure = FALSE)
      """
    Then the output includes
      """
      when("I add {int} cucumbers", function(int, context) {
      # when("I add {float} cucumbers", function(float, context) {
      pending()
      })

      then("the basket is full", function(context) {
      pending()
      })

      when("I empty the basket", function(context) {
      pending()
      })
      """
    And the output doesn't include "Scenario"
    And the output doesn't include "an empty basket"

  Scenario: A step undefined in several scenarios gets one snippet
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add cucumbers
          Given a full basket

        Scenario: Empty the basket
          Given a full basket
      """
    When I run
      """
      test("features", reporter = CucumberSnippetsReporter$new(), stop_on_failure = FALSE)
      """
    Then the output includes 'given("a full basket", function(context) {' 1 time

  Scenario: A run without undefined steps prints nothing
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Start shopping
          Given an empty basket
      """
    When I run
      """
      test("features", reporter = CucumberSnippetsReporter$new())
      """
    Then the output is empty
