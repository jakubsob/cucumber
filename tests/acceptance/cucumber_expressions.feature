Feature: Cucumber Expressions
  Step descriptions are Cucumber Expressions:
  text in parentheses is optional, words separated by "/" are alternatives,
  "{}" matches anything, and all other text is matched literally.

  Scenario: Optional text matches with or without it
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/expressions.feature" with
      """
      Feature: Optional text
        Scenario: Singular and plural
          Given I have 1 cucumber
          When I eat 2 cucumbers
          Then I have eaten 2 cucumbers
      """
    And a file named "features/setup-steps.R" with
      """
      given("I have {int} cucumber(s)", function(n, context) {
        context$n <- n
      })
      when("I eat {int} cucumber(s)", function(n, context) {
        context$eaten <- n
      })
      then("I have eaten {int} cucumber(s)", function(n, context) {
        expect_equal(context$eaten, n)
      })
      """
    When I run
      """
      test("features")
      """
    Then it passes

  Scenario: Alternative words match any of them
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/expressions.feature" with
      """
      Feature: Alternatives
        Scenario: Either key
          When I press the Enter key
          And I press the Return key
          Then the key was pressed 2 times
      """
    And a file named "features/setup-steps.R" with
      """
      when("I press the Enter/Return key", function(context) {
        context$presses <- sum(context$presses, 1)
      })
      then("the key was pressed {int} times", function(n, context) {
        expect_equal(context$presses, n)
      })
      """
    When I run
      """
      test("features")
      """
    Then it passes

  Scenario: Anonymous parameter matches anything as text
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/expressions.feature" with
      """
      Feature: Anonymous parameter
        Scenario: Any value
          Given the user is John Smith from 42 Street
          Then the user should be "John Smith from 42 Street"
      """
    And a file named "features/setup-steps.R" with
      """
      given("the user is {}", function(user, context) {
        context$user <- user
      })
      then("the user should be {string}", function(user, context) {
        expect_identical(context$user, user)
      })
      """
    When I run
      """
      test("features")
      """
    Then it passes

  Scenario: Special characters match literally and can be escaped
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/expressions.feature" with
      """
      Feature: Literal text
        Scenario: Punctuation
          Given the total is 5.00?
          When I visit /about
          Then I see (5) items on a/b
      """
    And a file named "features/setup-steps.R" with
      """
      given("the total is {float}?", function(total, context) {
        context$total <- total
      })
      when("I visit /about", function(context) {
        context$page <- "/about"
      })
      then("I see \\({int}) items on a\\/b", function(n, context) {
        expect_equal(n, 5L)
        expect_equal(context$total, 5)
        expect_equal(context$page, "/about")
      })
      """
    When I run
      """
      test("features")
      """
    Then it passes
