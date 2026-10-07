Feature: Gherkin parser
  Feature files are parsed like the official Gherkin parser does it.
  A line's meaning comes from its keyword, not from its indentation,
  and a file that isn't valid Gherkin fails with every error and its line:column.

  Scenario: Indentation doesn't matter
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/indent.feature" with
      """
      Feature: Indentation
      Scenario: Flat
      Given I have 1
      Then I should have 1
          Scenario: Tabs and a step deeper than the previous one
      	Given I have 1
      		Then I should have 1
      """
    And a file named "features/setup-steps.R" with
      """
      given("I have {int}", function(n, context) {
        context$n <- n
      })
      then("I should have {int}", function(n, context) {
        expect_equal(context$n, n)
      })
      """
    When I run
      """
      test("features")
      """
    Then it passes
    And it has 2 passed

  Scenario: A Doc String keeps empty lines and lines starting with #
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/docstring.feature" with
      """
      Feature: Doc Strings
        Scenario: A script
          Given a script
            ```r
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
        expect_equal(context$script, c("# Say hello", "", "print(\"hello\")"))
      })
      """
    When I run
      """
      test("features")
      """
    Then it passes
    And it has 1 passed

  Scenario: Outline placeholders are replaced in the name, Doc Strings and Data Tables
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/outline.feature" with
      """
      Feature: Outlines
        Scenario Outline: Greeting <name>
          Given a greeting
            ```
            Hello, <name>!
            ```
          And a person
            | name   |
            | <name> |
          Then the greeting is for the person

          Examples: People
            These are the people we greet.
            | name  |
            | Alice |
            | Bob   |
      """
    And a file named "features/setup-steps.R" with
      """
      given("a greeting", function(greeting, context) {
        context$greeting <- greeting
      })
      given("a person", function(person, context) {
        context$name <- person$name
      })
      then("the greeting is for the person", function(context) {
        expect_equal(context$greeting, paste0("Hello, ", context$name, "!"))
      })
      """
    When I run
      """
      test("features")
      """
    Then it passes
    And it has 2 passed
    And it ran "Scenario: Greeting Alice"
    And it ran "Scenario: Greeting Bob"

  Scenario: A step gets both a Doc String and a Data Table, in the order they are written
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/arguments.feature" with
      """
      Feature: Step arguments
        Scenario: Both arguments
          Given a request
            | header | value |
            | Accept | json  |
            ```json
            {"id": 1}
            ```
          Then the request is ready
      """
    And a file named "features/setup-steps.R" with
      """
      given("a request", function(headers, body, context) {
        context$headers <- headers
        context$body <- body
      })
      then("the request is ready", function(context) {
        expect_equal(list(context$headers$value, context$body), list("json", "{\"id\": 1}"))
      })
      """
    When I run
      """
      test("features")
      """
    Then it passes
    And it has 1 passed

  Scenario: Data Table cells unescape \n, \| and \\
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/table.feature" with
      """
      Feature: Escapes
        Scenario: Escaped cells
          Given cells
            | text |
            | a\nb |
            | a\|b |
            | a\\b |
          Then the cells are unescaped
      """
    And a file named "features/setup-steps.R" with
      """
      given("cells", function(table, context) {
        context$cells <- table$text
      })
      then("the cells are unescaped", function(context) {
        expect_equal(context$cells, c("a\nb", "a|b", "a\\b"))
      })
      """
    When I run
      """
      test("features")
      """
    Then it passes
    And it has 1 passed

  Scenario: A feature without scenarios runs nothing
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/empty.feature" with
      """
      Feature: Not written yet
        Scenarios will come later.
      """
    And a file named "features/setup-steps.R" with
      """
      given("a step", function(context) {})
      """
    When I run
      """
      test("features")
      """
    Then it passes
    And it has 0 passed

  Scenario: Every error in a feature file is reported with its line and column
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/broken.feature" with
      """
      Feature: Broken
        Scenario: Junk between steps
          Given a step
          this line is not a step
          Then a step
        Scenario: A ragged table
          Given a step
            | a | b |
            | c |
      """
    And a file named "features/setup-steps.R" with
      """
      given("a step", function(context) {})
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then it has 1 errors
    And the error message includes
      """
      (4:5): expected: #EOF, #TableRow, #DocStringSeparator, #StepLine, #TagLine, #ExamplesLine, #ScenarioLine, #RuleLine, #Comment, #Empty, got 'this line is not a step'
      """
    And the error message includes
      """
      (9:7): inconsistent cell count within the table
      """
