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

  Scenario Outline: A snippet for a step written with <keyword> after <previous> uses <function>()
    Steps written with `And` and `But` take the type of the step before them.

    Given a package
    And a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Shopping
          <previous> I start shopping
          <keyword> I pick a cucumber
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the error message includes
      """
      <function>("I pick a cucumber", function(context) {
      """

    Examples:
      | previous | keyword | function |
      | Given    | And     | given    |
      | When     | And     | when     |
      | Then     | But     | then     |

  Scenario: A step written with * is of unknown type, so its snippet uses given()
    `*` is a keyword of every step type, so unlike `And` and `But` it doesn't take the type of the step before it.

    Given a package
    And a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Shopping
          Then I start shopping
          * I pick a cucumber
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the error message includes
      """
      given("I pick a cucumber", function(context) {
      """

  Scenario: A snippet escapes the characters that Cucumber Expressions give a meaning to
    Given a package
    And a file named "features/pages.feature" with
      """
      Feature: Pages
        Scenario: Draft
          Given I visit /about (beta) {draft}
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the error message includes
      """
      given("I visit \\/about \\(beta) \\{draft}", function(context) {
      """

  Scenario: A snippet uses custom parameter types, unless they aren't for snippets
    Given a package
    And a file named "features/balls.feature" with
      """
      Feature: Balls
        Scenario: Pick a ball
          Given a big red ball
      """
    And a file named "features/setup-steps.R" with
      """
      define_parameter_type("colour", "red|green", as.character)
      define_parameter_type("size", "big|small", as.character, use_for_snippets = FALSE)
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the error message includes
      """
      given("a big {colour} ball", function(colour, context) {
      """
