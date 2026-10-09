Feature: Step definition snippets
  An undefined step is reported with a snippet of the step definition it needs, ready to paste into a setup file.
  When more than one parameter type matches a part of the step, the alternative step definitions are listed as comments.

  Scenario: An undefined step is reported with a snippet
    Given a package
    And a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Start shopping
          Given an empty basket
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then it has 1 failed
    And the error message includes
      """
      No step found for: "an empty basket"
      """
    And the error message includes
      """
      given("an empty basket", function(context) {
          pending()
        })
      """

  Scenario: Alternative step definitions are listed when more than one parameter type matches
    Given a package
    And a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Count cucumbers
          Given I have 5 cucumbers in my basket
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then it has 1 failed
    And the error message includes
      """
      given("I have {int} cucumbers in my basket", function(int, context) {
      # given("I have {float} cucumbers in my basket", function(float, context) {
          pending()
        })
      """

  Scenario: A quoted string becomes a {string} parameter
    Given a package
    And a file named "features/greet.feature" with
      """
      Feature: Greet
        Scenario: Say hello
          Given I see the message "hello world"
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

  Scenario: A snippet uses the step's keyword
    Given a package
    And a file named "features/pass.feature" with
      """
      Feature: Pass
        Scenario: It passes
          Then it passes
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

  Scenario: A snippet's parameters are in the order they are written
    Given a package
    And a file named "features/order.feature" with
      """
      Feature: Order
        Scenario: Mixed parameters
          Given "Alice" has 1.5 cucumbers and "Bob" has none
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the error message includes
      """
      given("{string} has {float} cucumbers and {string} has none", function(string, float, string2, context) {
      """

  Scenario: A snippet gets an argument for a data table or a doc string
    Given a package
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
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the error message includes
      """
      given("these people", function(data_table, context) {
      """
    And the error message includes
      """
      when("I send", function(doc_string, context) {
      """
