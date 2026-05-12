Feature: Parameter types

  Scenario: {int} captures an integer from step text
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/params.feature" with
      """
      Feature: Parameters
        Scenario: Integer parameter
          Given the count is 42
          Then I verify the count is 42
      """
    And a file named "features/setup-steps.R" with
      """
      given("the count is {int}", function(n, context) {
        context$value <- n
      })
      then("I verify the count is {int}", function(n, context) {
        expect_equal(context$value, n)
        expect_true(is.integer(context$value))
      })
      """
    When I run
      """
      test("features")
      """
    Then it passes
    And it has 2 passed

  Scenario: {float} captures a decimal number from step text
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/params.feature" with
      """
      Feature: Parameters
        Scenario: Float parameter
          Given the price is 3.99
          Then I verify the price is 3.99
      """
    And a file named "features/setup-steps.R" with
      """
      given("the price is {float}", function(price, context) {
        context$price <- price
      })
      then("I verify the price is {float}", function(price, context) {
        expect_equal(context$price, price)
        expect_true(is.double(context$price))
      })
      """
    When I run
      """
      test("features")
      """
    Then it passes
    And it has 2 passed

  Scenario: {string} captures a quoted string and strips quotes
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/params.feature" with
      """
      Feature: Parameters
        Scenario: String parameter double quotes
          Given the name is "Alice"
          Then I verify the name is "Alice"

        Scenario: String parameter single quotes
          Given the name is 'Bob'
          Then I verify the name is "Bob"
      """
    And a file named "features/setup-steps.R" with
      """
      given("the name is {string}", function(name, context) {
        context$name <- name
      })
      then("I verify the name is {string}", function(name, context) {
        expect_equal(context$name, name)
        expect_false(startsWith(context$name, "\""))
        expect_false(startsWith(context$name, "'"))
      })
      """
    When I run
      """
      test("features")
      """
    Then it passes
    And it has 6 passed

  Scenario: {word} captures a single unquoted word
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/params.feature" with
      """
      Feature: Parameters
        Scenario: Word parameter
          Given the colour is red
          Then I verify the colour is red
      """
    And a file named "features/setup-steps.R" with
      """
      given("the colour is {word}", function(colour, context) {
        context$colour <- colour
      })
      then("I verify the colour is {word}", function(colour, context) {
        expect_equal(context$colour, colour)
      })
      """
    When I run
      """
      test("features")
      """
    Then it passes
    And it has 1 passed

  Scenario: A custom parameter type can be registered and used in steps
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/params.feature" with
      """
      Feature: Parameters
        Scenario: Custom parameter
          Given the direction is north
          Then I verify the direction is north
      """
    And a file named "features/setup-steps.R" with
      """
      define_parameter_type(
        name = "direction",
        regexp = "north|south|east|west",
        transformer = toupper
      )
      given("the direction is {direction}", function(dir, context) {
        context$direction <- dir
      })
      then("I verify the direction is {direction}", function(dir, context) {
        expect_equal(context$direction, "NORTH")
      })
      """
    When I run
      """
      test("features")
      """
    Then it passes
    And it has 1 passed
