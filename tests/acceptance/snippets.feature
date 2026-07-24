Feature: Step definition snippets

  Scenario: Missing step shows a ready-to-paste snippet
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Count cucumbers
          Given I have 5 cucumbers in my basket
      """
    And a file named "features/setup-steps.R" with
      """
      given("some other step", function(context) {})
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then it has 1 errors
    And the error message includes "No step found for"
    And the error message includes
      """
      given("I have {int} cucumbers in my basket", function(int, context) {
          pending()
        })
      """

  Scenario: Missing step with a quoted string shows a string placeholder
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/greet.feature" with
      """
      Feature: Greet
        Scenario: Say hello
          Given I see the message "hello world"
      """
    And a file named "features/setup-steps.R" with
      """
      given("some other step", function(context) {})
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then it has 1 errors
    And the error message includes
      """
      given("I see the message {string}", function(string, context) {
          pending()
        })
      """

  Scenario: Snippet uses the step keyword
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/pass.feature" with
      """
      Feature: Pass
        Scenario: It passes
          Then it passes
      """
    And a file named "features/setup-steps.R" with
      """
      given("some other step", function(context) {})
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then it has 1 errors
    And the error message includes
      """
      then("it passes", function(context) {
          pending()
        })
      """
