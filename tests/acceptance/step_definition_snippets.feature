Feature: Step definition snippets
  An undefined step is reported with a snippet of the step definition it needs, ready to paste into a setup file.
  When more than one parameter type matches a part of the step, the alternative step definitions are listed as comments.
  Keep only one of them, as a step that matches several step definitions is ambiguous.

  @rd
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
    Then the steps have these results:
      | step                  | status    |
      | Given an empty basket | undefined |
    And the errors are
      """
      [failure] Scenario: Start shopping
      No step found for: "an empty basket"
      i Add a step definition:
        given("an empty basket", function(context) {
          pending()
        })
      """

  @rd
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
    Then the steps have these results:
      | step                                  | status    |
      | Given I have 5 cucumbers in my basket | undefined |
    And the errors are
      """
      [failure] Scenario: Count cucumbers
      No step found for: "I have 5 cucumbers in my basket"
      i Add a step definition:
        given("I have {int} cucumbers in my basket", function(int, context) {
        # given("I have {float} cucumbers in my basket", function(float, context) {
          pending()
        })
      """

  Scenario: Every combination of matching parameter types is listed, and a repeated type's argument is numbered
    Given a package
    And a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Count cucumbers
          Given I have 5 and 6 cucumbers
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the errors are
      """
      [failure] Scenario: Count cucumbers
      No step found for: "I have 5 and 6 cucumbers"
      i Add a step definition:
        given("I have {int} and {int} cucumbers", function(int, int2, context) {
        # given("I have {int} and {float} cucumbers", function(int, float, context) {
        # given("I have {float} and {int} cucumbers", function(float, int, context) {
        # given("I have {float} and {float} cucumbers", function(float, float2, context) {
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
    Then the errors are
      """
      [failure] Scenario: Say hello
      No step found for: "I see the message "hello world""
      i Add a step definition:
        given("I see the message {string}", function(string, context) {
          pending()
        })
      """

  Scenario: A snippet uses the step's keyword
    Given a package
    And a file named "features/result.feature" with
      """
      Feature: Result
        Scenario: Show the result
          Then the result is shown
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the errors are
      """
      [failure] Scenario: Show the result
      No step found for: "the result is shown"
      i Add a step definition:
        then("the result is shown", function(context) {
          pending()
        })
      """

  Scenario: An undefined step of a Background is reported with a snippet
    Given a package
    And a file named "features/basket.feature" with
      """
      Feature: Basket
        Background:
          Given an empty basket

        Scenario: Start shopping
          When I start shopping
      """
    And a file named "features/setup-steps.R" with
      """
      when("I start shopping", function(context) {})
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the errors are
      """
      [failure] Scenario: Start shopping
      No step found for: "an empty basket"
      i Add a step definition:
        given("an empty basket", function(context) {
          pending()
        })
      """

  Scenario: A snippet of a step written in another language uses the step's keyword
    Given a package
    And a file named "features/panier.feature" with
      """
      # language: fr
      Fonctionnalité: Panier
        Scénario: Panier vide
          Alors le panier est vide
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the errors are
      """
      [failure] Scenario: Panier vide
      No step found for: "le panier est vide"
      i Add a step definition:
        then("le panier est vide", function(context) {
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
    Then the errors are
      """
      [failure] Scenario: Mixed parameters
      No step found for: ""Alice" has 1.5 cucumbers and "Bob" has none"
      i Add a step definition:
        given("{string} has {float} cucumbers and {string} has none", function(string, float, string2, context) {
          pending()
        })
      """

  Scenario: A snippet gets an argument for a Data Table or a Doc String
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
    Then the errors are
      """
      [failure] Scenario: Step arguments
      No step found for: "these people"
      i Add a step definition:
        given("these people", function(data_table, context) {
          pending()
        })

      [failure] Scenario: Step arguments
      No step found for: "I send"
      i Add a step definition:
        when("I send", function(doc_string, context) {
          pending()
        })
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
    And a file named "features/setup-steps.R" with
      """
      given("I start shopping", function(context) {})
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the errors are
      """
      [failure] Scenario: Shopping
      No step found for: "I pick a cucumber"
      i Add a step definition:
        <function>("I pick a cucumber", function(context) {
          pending()
        })
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
    Then the errors are
      """
      [failure] Scenario: Shopping
      No step found for: "I start shopping"
      i Add a step definition:
        then("I start shopping", function(context) {
          pending()
        })

      [failure] Scenario: Shopping
      No step found for: "I pick a cucumber"
      i Add a step definition:
        given("I pick a cucumber", function(context) {
          pending()
        })
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
    Then the errors are
      """
      [failure] Scenario: Draft
      No step found for: "I visit /about (beta) {draft}"
      i Add a step definition:
        given("I visit \\/about \\(beta) \\{draft}", function(context) {
          pending()
        })
      """

  Scenario: A snippet's arguments are valid R names, other than those of the step's other arguments
    Given a package
    And a file named "features/calendar.feature" with
      """
      Feature: Calendar
        Scenario: Plan a meeting
          Given a meeting on 2024-01-31 in the office
      """
    And a file named "features/setup-steps.R" with
      """
      define_parameter_type("iso-date", "\\d{4}-\\d{2}-\\d{2}", as.Date)
      define_parameter_type("context", "office|home", as.character)
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the errors are
      """
      [failure] Scenario: Plan a meeting
      No step found for: "a meeting on 2024-01-31 in the office"
      i Add a step definition:
        given("a meeting on {iso-date} in the {context}", function(iso_date, arg, context) {
          pending()
        })
      """

  Scenario: A step that starts with ^ or ends with $ gets a regular expression snippet of its text
    A step description that starts with `^` or ends with `$` is a regular expression, and a Cucumber Expression can't escape them.

    Given a package
    And a file named "features/symbols.feature" with
      """
      Feature: Symbols
        Scenario: Caret
          Given ^ is a caret
        Scenario: Price
          When I pay 5$
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the errors are
      """
      [failure] Scenario: Caret
      No step found for: "^ is a caret"
      i Add a step definition:
        given("^\\^ is a caret$", function(context) {
          pending()
        })

      [failure] Scenario: Price
      No step found for: "I pay 5$"
      i Add a step definition:
        when("^I pay 5\\$$", function(context) {
          pending()
        })
      """

  Scenario: The regular expression snippet matches its step
    Given a package
    And a file named "features/symbols.feature" with
      """
      Feature: Symbols
        Scenario: Caret
          Given ^ is a caret
        Scenario: Price
          When I pay 5$
      """
    And a file named "features/setup-steps.R" with
      """
      given("^\\^ is a caret$", function(context) {
        pending()
      })
      when("^I pay 5\\$$", function(context) {
        pending()
      })
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the steps have these results:
      | step               | status  |
      | Given ^ is a caret | pending |
      | When I pay 5$      | pending |

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
    Then the errors are
      """
      [failure] Scenario: Pick a ball
      No step found for: "a big red ball"
      i Add a step definition:
        given("a big {colour} ball", function(colour, context) {
          pending()
        })
      """
