Feature: Docstring step arguments

  Scenario: A step receives a docstring as its last argument
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/docstring.feature" with
      """
      Feature: Docstrings
        Scenario: Step with docstring
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

  Scenario: Docstring preserves multiple lines
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/docstring.feature" with
      """
      Feature: Docstrings
        Scenario: Multiline docstring
          Given a message
            ```
            line one
            line two
            ```
          Then the message has 2 lines
      """
    And a file named "features/setup-steps.R" with
      """
      given("a message", function(message, context) {
        context$message <- message
      })
      then("the message has {int} lines", function(n, context) {
        expect_equal(length(context$message), n)
      })
      """
    When I run
      """
      test("features")
      """
    Then it passes
    And it has 1 passed

  Scenario: Docstring combined with parameter placeholders in step description
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/docstring.feature" with
      """
      Feature: Docstrings
        Scenario: Docstring with parameter
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

  Scenario: Docstring content is dedented relative to its opening delimiter
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/docstring.feature" with
      """
      Feature: Docstrings
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
        expect_equal(
          context$message,
          c("foo:", "- bar: bar_value", "  baz: baz_value")
        )
      })
      """
    When I run
      """
      test("features")
      """
    Then it passes
    And it has 2 passed
