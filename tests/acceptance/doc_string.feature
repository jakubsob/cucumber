Feature: Doc Strings
  A Doc String is a block of text under a step, between ``` or """ delimiters.
  The step definition gets it as one string, after the step's parameters.

  Background:
    Given a package

  Rule: A step definition gets the Doc String as one string, after the step's parameters

    Scenario: A step definition gets the Doc String
      Given a file named "features/docstring.feature" with
        """
        Feature: Doc Strings
          Scenario: Step with a Doc String
            Given a message
              ```
              Hello, world!
              ```
            Then the message is "Hello, world!"
        """
      And a file named "features/setup-steps.R" with
        """
        given("a message", function(message, context) {
          context$message <- message
        })
        then("the message is {string}", function(expected, context) {
          expect_equal(context$message[[1]], expected)
        })
        """
      When I run
        """
        test("features")
        """
      Then it passes
      And it has 1 passed

    Scenario: A Doc String can be between """ delimiters
      Given a file named "features/docstring.feature" with
        """
        Feature: Doc Strings
          Scenario: Step with a Doc String
            Given a message
              \"\"\"
              Hello, world!
              \"\"\"
            Then the message is "Hello, world!"
        """
      And a file named "features/setup-steps.R" with
        """
        given("a message", function(message, context) {
          context$message <- message
        })
        then("the message is {string}", function(expected, context) {
          expect_equal(context$message[[1]], expected)
        })
        """
      When I run
        """
        test("features")
        """
      Then it passes
      And it has 1 passed

    Scenario: A multi-line Doc String is one string with its lines joined by newlines
      Given a file named "features/docstring.feature" with
        """
        Feature: Doc Strings
          Scenario: Multi-line Doc String
            Given a message
              ```
              line one
              line two
              ```
            Then the message has both lines
        """
      And a file named "features/setup-steps.R" with
        """
        given("a message", function(message, context) {
          context$message <- message
        })
        then("the message has both lines", function(context) {
          expect_equal(context$message, "line one\nline two")
        })
        """
      When I run
        """
        test("features")
        """
      Then it passes
      And it has 1 passed

    Scenario: A Doc String comes after the step's parameters
      Given a file named "features/docstring.feature" with
        """
        Feature: Doc Strings
          Scenario: Doc String with a parameter
            Given file "greeting.txt" contains
              ```
              Hello!
              ```
            Then file "greeting.txt" has content "Hello!"
        """
      And a file named "features/setup-steps.R" with
        """
        given("file {string} contains", function(filename, content, context) {
          context$files <- c(context$files, setNames(list(content[[1]]), filename))
        })
        then("file {string} has content {string}", function(filename, expected, context) {
          expect_equal(context$files[[filename]], expected)
        })
        """
      When I run
        """
        test("features")
        """
      Then it passes
      And it has 1 passed

    Scenario: A Doc String is dedented relative to its opening delimiter
      Given a file named "features/docstring.feature" with
        """
        Feature: Doc Strings
          Scenario: Delimiter indented past the step
            Given a message
              ```
              foo:
              - bar: bar_value
                baz: baz_value
              ```
            Then the message is the indented yaml
          Scenario: Delimiter aligned with the step
            Given a message
            ```
            foo:
            - bar: bar_value
              baz: baz_value
            ```
            Then the message is the indented yaml
        """
      And a file named "features/setup-steps.R" with
        """
        given("a message", function(message, context) {
          context$message <- message
        })
        then("the message is the indented yaml", function(context) {
          expect_equal(context$message, "foo:\n- bar: bar_value\n  baz: baz_value")
        })
        """
      When I run
        """
        test("features")
        """
      Then it passes
      And it has 2 passed

    Scenario: A Doc String keeps empty lines and lines starting with #
      Given a file named "features/docstring.feature" with
        """
        Feature: Doc Strings
          Scenario: A script
            Given a script
              ```
              # Say hello

              print("hello")
              ```
            Then the script keeps every line
        """
      And a file named "features/setup-steps.R" with
        """
        given("a script", function(script, context) {
          context$script <- script
        })
        then("the script keeps every line", function(context) {
          expect_equal(context$script, "# Say hello\n\nprint(\"hello\")")
        })
        """
      When I run
        """
        test("features")
        """
      Then it passes
      And it has 1 passed

  Rule: The media type is in the string's `media_type` attribute

    It is `json` for a Doc String opened with ```json.

    Scenario: A Doc String's media type is in its media_type attribute
      Given a file named "features/docstring.feature" with
        """
        Feature: Doc Strings
          Scenario: A request body
            Given a body
              ```json
              {"id": 1}
              ```
            Then the body is JSON
          Scenario: Text without a media type
            Given a body
              ```
              Hello
              ```
            Then the body has no media type
        """
      And a file named "features/setup-steps.R" with
        """
        given("a body", function(body, context) {
          context$body <- body
        })
        then("the body is JSON", function(context) {
          expect_equal(attr(context$body, "media_type"), "json")
          expect_equal(c(context$body), "{\"id\": 1}")
        })
        then("the body has no media type", function(context) {
          expect_null(attr(context$body, "media_type"))
        })
        """
      When I run
        """
        test("features")
        """
      Then it passes
      And it has 2 passed

  Rule: In R, the `cucumber.docstring_as_lines` option passes a Doc String as a character vector of lines

    Scenario: The cucumber.docstring_as_lines option passes a Doc String as a character vector of lines
      Given a file named "features/docstring.feature" with
        """
        Feature: Doc Strings
          Scenario: A script
            Given a script
              ```r
              x <- 1
              y <- 2
              ```
            Then the script is a vector of lines
        """
      And a file named "features/setup-steps.R" with
        """
        given("a script", function(script, context) {
          context$script <- script
        })
        then("the script is a vector of lines", function(context) {
          expect_equal(c(context$script), c("x <- 1", "y <- 2"))
          expect_equal(attr(context$script, "media_type"), "r")
        })
        """
      When I run
        """
        withr::with_options(list(cucumber.docstring_as_lines = TRUE), test("features"))
        """
      Then it passes
      And it has 1 passed
