Feature: Cucumber Expressions
  Step descriptions are Cucumber Expressions:
  text in parentheses is optional, words separated by "/" are alternatives,
  "{}" matches anything, and all other text is matched literally.
  An invalid expression is an error pointing at the problem.

  @rd
  Scenario: Optional text matches with or without it
    Given a package
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

  @rd
  Scenario: Alternative words match any of them
    Given a package
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

  @rd
  Scenario: Anonymous parameter matches anything as text
    Given a package
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

  @rd
  Scenario: Text is matched literally, not as a regular expression
    Given a package
    And a file named "features/expressions.feature" with
      """
      Feature: Literal text
        Scenario: A dot
          Given the version is 1.5

        Scenario: Any character
          Given the version is 105
      """
    And a file named "features/setup-steps.R" with
      """
      given("the version is 1.5", function(context) {})
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the steps have these results:
      | step                     | status    |
      | Given the version is 1.5 | passed    |
      | Given the version is 105 | undefined |

  Scenario: Special characters match literally and can be escaped
    Given a package
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
      when("I visit \\/about", function(context) {
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

  @rd
  Scenario: An escaped space keeps words together in an alternative
    Given a package
    And a file named "features/expressions.feature" with
      """
      Feature: Alternatives with spaces
        Scenario: Either city
          Given I lived in New York
          And I lived in Boston
          Then I lived in 2 cities
      """
    And a file named "features/setup-steps.R" with
      """
      given("I lived in New\\ York/Boston", function(context) {
        context$cities <- sum(context$cities, 1)
      })
      then("I lived in {int} cities", function(n, context) {
        expect_equal(context$cities, n)
      })
      """
    When I run
      """
      test("features")
      """
    Then it passes

  Scenario: An invalid expression is an error, with how to escape a character in an R string
    Given a package
    And a file named "features/expressions.feature" with
      """
      Feature: Invalid expression
        Scenario: About page
          When I visit /about
      """
    And a file named "features/setup-steps.R" with
      """
      when("I visit /about", function(context) {})
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the errors are
      """
      [error]
      Error: Step definition "I visit /about" is invalid
      i Step defined at: setup-steps.R:1
      Caused by error:
      ! This Cucumber Expression has a problem at column 9:

      I visit /about
              ^
      Alternative may not be empty.
      If you did not mean to use an alternative you can use '\/' to escape the '/'
      In an R string, double each backslash: "\\/".
      """

  Scenario: An invalid expression is an error, parameter name with parenthesis
    Given a package
    And a file named "features/expressions.feature" with
      """
      Feature: Invalid expression
        Scenario: Cucumbers
          Given I have cucumbers
      """
    And a file named "features/setup-steps.R" with
      """
      given(r"[I have {i(n)t}]", function(context) {})
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the errors are
      """
      [error]
      Error: Step definition "I have {i(n)t}" is invalid
      i Step defined at: setup-steps.R:1
      Caused by error:
      ! This Cucumber Expression has a problem at column 10:

      I have {i(n)t}
               ^
      Parameter names may not contain '{', '}', '(', ')', '\' or '/'.
      Did you mean to use a regular expression?
      """
