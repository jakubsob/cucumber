Feature: Parameter types
  A parameter like `{int}` in a step definition's Cucumber Expression captures a part of the step
  and passes it to the step definition converted to an R value.
  Register your own with `define_parameter_type()`.

  Background:
    Given a package

  Rule: Built-in parameter types convert the text to R values

    Scenario: {int} captures an integer from step text
      Given a file named "features/params.feature" with
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
      And it has 1 passed

    Scenario: {int} matches only integers without a plus sign
      Given a file named "features/params.feature" with
        """
        Feature: Parameters
          Scenario: Plus sign
            Given the count is +5
        """
      And a file named "features/setup-steps.R" with
        """
        given("the count is {int}", function(n, context) {})
        """
      When I run
        """
        test("features", stop_on_failure = FALSE)
        """
      Then the error message includes "No step found for: \"the count is +5\""

    Scenario: {float} captures a decimal number from step text
      Given a file named "features/params.feature" with
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
      And it has 1 passed

    Scenario: {float} also captures an integer
      Given a file named "features/params.feature" with
        """
        Feature: Parameters
          Scenario: Integer as a float
            Given the price is 12
            Then I verify the price is 12
        """
      And a file named "features/setup-steps.R" with
        """
        given("the price is {float}", function(price, context) {
          context$price <- price
        })
        then("I verify the price is {float}", function(price, context) {
          expect_identical(context$price, price)
          expect_identical(context$price, 12)
        })
        """
      When I run
        """
        test("features")
        """
      Then it passes

    Scenario: {string} captures a quoted string and strips quotes
      Given a file named "features/params.feature" with
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
      And it has 2 passed

    Scenario: {string} unescapes escaped quotes
      Given a file named "features/params.feature" with
        """
        Feature: Parameters
          Scenario: Escaped quotes
            Given the message is "say \"hi\""
            And the reply is 'it\'s me'
        """
      And a file named "features/setup-steps.R" with
        """
        given("the message is {string}", function(message, context) {
          expect_equal(message, "say \"hi\"")
        })
        given("the reply is {string}", function(reply, context) {
          expect_equal(reply, "it's me")
        })
        """
      When I run
        """
        test("features")
        """
      Then it passes

    Scenario: {word} captures a single unquoted word
      Given a file named "features/params.feature" with
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

    Scenario: {word} matches anything without whitespace
      Given a file named "features/params.feature" with
        """
        Feature: Parameters
          Scenario: Word with a hyphen
            Given the colour is blue-green
        """
      And a file named "features/setup-steps.R" with
        """
        given("the colour is {word}", function(colour, context) {
          expect_equal(colour, "blue-green")
        })
        """
      When I run
        """
        test("features")
        """
      Then it passes

  Rule: {int} is an R integer

    Scenario: {int} fails on a value too big for an R integer
      Given a file named "features/params.feature" with
        """
        Feature: Parameters
          Scenario: Big number
            Given the count is 3000000000
        """
      And a file named "features/setup-steps.R" with
        """
        given("the count is {int}", function(n, context) {})
        """
      When I run
        """
        test("features", stop_on_failure = FALSE)
        """
      Then it has 1 errors
      And the error message includes "3000000000 is out of range for an integer"

  Rule: Custom parameter types are defined with define_parameter_type()

    Scenario: A custom parameter type can be registered and used in steps
      Given a file named "features/params.feature" with
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

    Scenario: A custom parameter type's regexp is a plain regular expression
      Given a file named "features/params.feature" with
        """
        Feature: Parameters
          Scenario: Version
            Given the version is 1.2
        """
      And a file named "features/setup-steps.R" with
        """
        define_parameter_type("version", "\\d+\\.\\d+", numeric_version)
        given("the version is {version}", function(version, context) {
          expect_equal(version, numeric_version("1.2"))
        })
        """
      When I run
        """
        test("features")
        """
      Then it passes

    Scenario: A custom parameter type's transformer gets the text of each capture group
      Given a file named "features/params.feature" with
        """
        Feature: Parameters
          Scenario: Point
            Given a point at 1,2 and 3 more
        """
      And a file named "features/setup-steps.R" with
        """
        define_parameter_type("point", "(\\d+),(\\d+)", function(x, y) as.integer(c(x, y)))
        given("a point at {point} and {int} more", function(point, n, context) {
          expect_equal(point, c(1L, 2L))
          expect_equal(n, 3L)
        })
        """
      When I run
        """
        test("features")
        """
      Then it passes

    Scenario: A parameter type can't be defined twice
      When I run it and it fails
        """
        define_parameter_type("int", "\\d+", as.integer)
        """
      Then it fails with "There is already a parameter type with name int"

    Scenario: A parameter type's name can't contain {, }, (, ), \ or /
      When I run it and it fails
        """
        define_parameter_type("a/b", "x", as.character)
        """
      Then it fails with "Illegal character in parameter name {a/b}."

    Scenario: Only one parameter type with the same regexp can be preferred for regular expressions
      When I run it and it fails
        """
        define_parameter_type("count", "-?\\d+", as.integer, prefer_for_regexp_match = TRUE)
        """
      Then it fails with "There can only be one preferential parameter type per regexp. The regexp /-?\d+/ is used for two preferential parameter types, {int} and {count}"
