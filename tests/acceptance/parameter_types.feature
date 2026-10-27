Feature: Parameter types
  A parameter like `{int}` in a step definition's Cucumber Expression captures a part of the step
  and passes it to the step definition converted to an R value.
  Register your own with `define_parameter_type()`.

  Background:
    Given a package

  Rule: Built-in parameter types convert the text to R values

    @rd
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
        then("I verify the count is 42", function(context) {
          expect_identical(context$value, 42L)
        })
        """
      When I run
        """
        test("features")
        """
      Then it passes

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
      Then the errors are
        """
        [failure] Scenario: Plus sign
        No step found for: "the count is +5"
        i Add a step definition:
          given("the count is {float}", function(float, context) {
            pending()
          })
        """

    @rd
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
        then("I verify the price is 3.99", function(context) {
          expect_identical(context$price, 3.99)
        })
        """
      When I run
        """
        test("features")
        """
      Then it passes

    @rd
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

    Scenario: {float} captures a number with an exponent
      Given a file named "features/params.feature" with
        """
        Feature: Parameters
          Scenario: Exponents
            Given the distance is 1.5E3
            And the size is -2E-3
        """
      And a file named "features/setup-steps.R" with
        """
        given("the distance is {float}", function(distance, context) {
          expect_identical(distance, 1500)
        })
        given("the size is {float}", function(size, context) {
          expect_identical(size, -0.002)
        })
        """
      When I run
        """
        test("features")
        """
      Then it passes

    @rd
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
      Then the scenarios have these results:
        | scenario                       | status |
        | String parameter double quotes | passed |
        | String parameter single quotes | passed |

    Scenario: {string} captures an empty string
      Given a file named "features/params.feature" with
        """
        Feature: Parameters
          Scenario: Empty name
            Given the name is ""
        """
      And a file named "features/setup-steps.R" with
        """
        given("the name is {string}", function(name, context) {
          expect_identical(name, "")
        })
        """
      When I run
        """
        test("features")
        """
      Then the steps have these results:
        | step                 | status |
        | Given the name is "" | passed |

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

    @rd
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
        then("I verify the colour is red", function(context) {
          expect_identical(context$colour, "red")
        })
        """
      When I run
        """
        test("features")
        """
      Then it passes

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

    @rd
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
      Then the steps have these results:
        | step                          | status |
        | Given the count is 3000000000 | failed |
      And the errors are
        """
        [error] Scenario: Big number
        Error: Step "the count is 3000000000" failed
        i Feature: params.feature
        i Scenario: Big number
        i Step defined at: setup-steps.R:1
        Caused by error:
        ! Parameter type {int} failed to transform "3000000000".
        Caused by error:
        ! It's out of the range of an R integer.
        """

  Rule: {byte}, {short}, {long} and {double} are built in too, for feature files shared with other Cucumber implementations

    @rd
    Scenario Outline: {<type>} gives <value>
      Given a file named "features/params.feature" with
        """
        Feature: Parameters
          Scenario: Number
            Given the number is <text>
        """
      And a file named "features/setup-steps.R" with
        """
        given("the number is {<type>}", function(x, context) {
          expect_identical(x, <value>)
        })
        """
      When I run
        """
        test("features")
        """
      Then it passes

      Examples:
        | type   | text       | value |
        | byte   | -12        | -12L  |
        | short  | 300        | 300L  |
        | long   | 3000000000 | 3e9   |
        | double | 1.5E3      | 1500  |

  Rule: Custom parameter types are defined with define_parameter_type()

    @rd
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

    Scenario: A parameter type can be defined in a file loaded after the steps that use it
      Setup files are loaded in alphabetical order, so `setup-steps.R` is loaded before `setup-types.R`.

      Given a file named "features/params.feature" with
        """
        Feature: Parameters
          Scenario: Custom parameter
            Given the direction is north
        """
      And a file named "features/setup-steps.R" with
        """
        given("the direction is {direction}", function(dir, context) {
          expect_equal(dir, "NORTH")
        })
        """
      And a file named "features/setup-types.R" with
        """
        define_parameter_type(
          name = "direction",
          regexp = "north|south|east|west",
          transformer = toupper
        )
        """
      When I run
        """
        test("features")
        """
      Then the steps have these results:
        | step                         | status |
        | Given the direction is north | passed |

    @rd
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

    @rd
    Scenario: A custom parameter type can have several regexps
      Given a file named "features/params.feature" with
        """
        Feature: Parameters
          Scenario: Answers
            Given the answer is yes
            And the answer is no
        """
      And a file named "features/setup-steps.R" with
        """
        define_parameter_type("answer", c("yes", "no"), \(x) x == "yes")
        given("the answer is {answer}", function(answer, context) {
          context$answers <- c(context$answers, answer)
          if (length(context$answers) == 2) expect_identical(context$answers, c(TRUE, FALSE))
        })
        """
      When I run
        """
        test("features")
        """
      Then it passes

    @rd
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

    @rd
    Scenario: A transformer's error fails the step and names the parameter type
      The error is shown with the backtrace of the transformer.

      Given a file named "features/params.feature" with
        """
        Feature: Parameters
          Scenario: Colour
            Given the colour is blue
        """
      And a file named "features/setup-steps.R" with
        """
        check_colour <- function(x) stop("Unknown colour: ", x)
        define_parameter_type("colour", "[a-z]+", function(x) check_colour(x))
        given("the colour is {colour}", function(colour, context) {})
        """
      When I run
        """
        test("features", stop_on_failure = FALSE)
        """
      Then the steps have these results:
        | step                     | status |
        | Given the colour is blue | failed |
      And the errors are
        """
        [error] Scenario: Colour
        Error: Step "the colour is blue" failed
        i Feature: params.feature
        i Scenario: Colour
        i Step defined at: setup-steps.R:3
        Caused by error:
        ! Parameter type {colour} failed to transform "blue".
        Caused by error in `check_colour()`:
        ! Unknown colour: blue
        """
      And the output includes lines matching these patterns in order:
        """
        Unknown colour: blue
        ^Backtrace:$
        1\. .*check_colour\(x\)
        """
      And the output doesn't include "test_that"

    Scenario: A parameter type can't be defined twice
      When I run it and it fails
        """
        define_parameter_type("int", "\\d+", as.integer)
        """
      Then it fails with
        """
        Error:
        ! There is already a parameter type with name int
        """

    Scenario: A parameter type's name can't contain {, }, (, ), \ or /
      When I run it and it fails
        """
        define_parameter_type("a/b", "x", as.character)
        """
      Then it fails with
        """
        Error:
        ! Illegal character in parameter name {a/b}. Parameter names may not contain '{', '}', '(', ')', '\' or '/'
        """

    Scenario: A parameter type must have a name
      When I run it and it fails
        """
        define_parameter_type("", "x", as.character)
        """
      Then it fails with
        """
        Error:
        ! A parameter type must have a name, as {} is the anonymous parameter type.
        """

    Scenario: A parameter type's transformer must be a function
      When I run it and it fails
        """
        define_parameter_type("colour", "red|green", "as.character")
        """
      Then it fails with
        """
        Error in define_parameter_type("colour", "red|green", "as.character"): Assertion on 'transformer' failed: Must be a function, not 'character'.
        """

    Scenario: A parameter type with an invalid regexp is an error
      When I run it and it fails
        """
        define_parameter_type("colour", c("red", "(green"), as.character)
        """
      Then it fails with
        """
        Error:
        ! The regexp /(green/ of parameter type {colour} is invalid.
        x Incorrectly nested parentheses in regex pattern. (U_REGEX_MISMATCHED_PAREN, context=`(green`)
        """

    Scenario: Only one parameter type with the same regexp can be preferred for regular expressions
      When I run it and it fails
        """
        define_parameter_type("count", "-?\\d+", as.integer, prefer_for_regexp_match = TRUE)
        """
      Then it fails with
        """
        Error:
        ! There can only be one preferential parameter type per regexp. The regexp /-?\d+/ is used for two preferential parameter types, {int} and {count}
        """

  Rule: A step definition with an undefined parameter type defines no step
    The run goes on: the steps it would match are undefined, and the
    summary lists the undefined parameter types.

    @rd
    Scenario: Steps of a step definition with an undefined parameter type are undefined
      Given a file named "features/airports.feature" with
        """
        Feature: Airports
          Scenario: Strike
            Given CDG is closed because of a strike

          Scenario: Open
            Given LHR is open
        """
      And a file named "features/setup-steps.R" with
        """
        given("{airport} is closed because of a strike", function(airport, context) {})
        given("LHR is open", function(context) {})
        """
      When I run
        """
        test("features", stop_on_failure = FALSE)
        """
      Then the steps have these results:
        | scenario | step                                    | status    |
        | Strike   | Given CDG is closed because of a strike | undefined |
        | Open     | Given LHR is open                       | passed    |
      And the output includes
        """
        Undefined parameter types:
        - "airport" e.g. `{airport} is closed because of a strike`
        """
