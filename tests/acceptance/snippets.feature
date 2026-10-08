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
    Then it has 1 failed
    And the error message includes "No step found for"
    And the error message includes
      """
      given("I have {int} cucumbers in my basket", function(int, context) {
      # given("I have {float} cucumbers in my basket", function(float, context) {
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
    Then it has 1 failed
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
    Then it has 1 failed
    And the error message includes
      """
      then("it passes", function(context) {
          pending()
        })
      """

  Scenario: Snippet parameters are in the order they are written
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/order.feature" with
      """
      Feature: Order
        Scenario: Mixed parameters
          Given "Alice" has 1.5 cucumbers and "Bob" has none
      """
    And a file named "features/setup-steps.R" with
      """
      given("some other step", function(context) {})
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the error message includes
      """
      given("{string} has {float} cucumbers and {string} has none", function(string, float, string2, context) {
      """

  Scenario: Snippet for a step with a data table or a doc string
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/arguments.feature" with
      """
      Feature: Arguments
        Scenario: Step arguments
          Given these people
            | name  |
            | Alice |
          When I send
            ```
            hello
            ```
      """
    And a file named "features/setup-steps.R" with
      """
      given("some other step", function(context) {})
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the error message includes
      """
      given("these people", function(dataTable, context) {
      """
    And the error message includes
      """
      when("I send", function(docString, context) {
      """
