Feature: Regular expressions
  A step description that starts with "^", ends with "$" or is surrounded by "/"
  is a regular expression instead of a Cucumber Expression.
  Each capture group is passed to the step. A group whose regexp is the regexp of a parameter type,
  like `(\\d+)` for `{int}`, is converted like that parameter; any other group is passed as text.
  A regular expression without "^" and "$" can match a part of the step's text.

  @rd
  Scenario: Capture groups are passed to the step, converted by parameter type
    Given a package
    And a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Colours
          Given I have a red cucumber
          And I have a green cucumber
          Then I have 2 cucumbers
      """
    And a file named "features/setup-steps.R" with
      """
      given("^I have a (red|green) cucumber$", function(colour, context) {
        context$colours <- c(context$colours, colour)
      })
      then("/I have (\\d+) cucumbers/", function(n, context) {
        expect_identical(n, 2L)
        expect_equal(context$colours, c("red", "green"))
      })
      """
    When I run
      """
      test("features")
      """
    Then it passes

  Scenario: A group with the regexp of a negative {int} is converted to an integer
    Given a package
    And a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Debt
          Then I owe -3 cucumbers
      """
    And a file named "features/setup-steps.R" with
      """
      then("^I owe (-?\\d+) cucumbers$", function(n, context) {
        expect_identical(n, -3L)
      })
      """
    When I run
      """
      test("features")
      """
    Then it passes

  @rd
  Scenario: A capture group that doesn't match passes NA
    Given a package
    And a file named "features/vegetables.feature" with
      """
      Feature: Vegetables
        Scenario: Optional groups
          Given a cucumber and a carrot
          Then the vegetables are cucumber and carrot
      """
    And a file named "features/setup-steps.R" with
      """
      given("^a (.*?)(?: and a (.*?))?(?: and a (.*?))?$", function(first, second, third, context) {
        context$vegetables <- c(first, second, third)
      })
      then("^the vegetables are cucumber and carrot$", function(context) {
        expect_equal(context$vegetables, c("cucumber", "carrot", NA))
      })
      """
    When I run
      """
      test("features")
      """
    Then it passes

  Scenario: An invalid regular expression is an error that shows it
    Given a package
    And a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Pay
          Given I pay 5
      """
    And a file named "features/setup-steps.R" with
      """
      given("I pay {int}$", function(n, context) {})
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the error message includes "This Regular Expression has a problem:"
    And the error message includes "I pay {int}$"

  Scenario: A character class can start with ]
    Given a package
    And a file named "features/brackets.feature" with
      """
      Feature: Brackets
        Scenario: Brackets
          Given the brackets ]( and 3
      """
    And a file named "features/setup-steps.R" with
      """
      given("^the brackets ([](]+) and (\\d+)$", function(brackets, n, context) {
        expect_equal(brackets, "](")
        expect_identical(n, 3L)
      })
      """
    When I run
      """
      test("features")
      """
    Then it passes

  Scenario: A group with the regexp of two parameter types is an error unless one is preferred
    Given a package
    And a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Colours
          Given I have a red cucumber
      """
    And a file named "features/setup-steps.R" with
      """
      define_parameter_type("colour", "red|green", as.character)
      define_parameter_type("ripeness", "red|green", as.character)
      given("^I have a (red|green) cucumber$", function(colour, context) {})
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then it has 1 failed
    And the error message includes
      """
      Your Regular Expression ^I have a (red|green) cucumber$
      matches multiple parameter types with regexp red|green:
      {colour}
      {ripeness}
      """
    And the error message includes "with `prefer_for_regexp_match = TRUE`."
