Feature: Data table step arguments

  Scenario: A step receives a data table as a tibble
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/table.feature" with
      """
      Feature: Tables
        Scenario: Step with table
          Given a list of numbers
            | value |
            | 1     |
            | 2     |
            | 3     |
          Then the sum is 6
      """
    And a file named "features/setup-steps.R" with
      """
      given("a list of numbers", function(table, context) {
        context$numbers <- as.integer(table$value)
      })
      then("the sum is {int}", function(n, context) {
        expect_equal(sum(context$numbers), n)
      })
      """
    When I run
      """
      test("features")
      """
    Then it passes
    And it has 1 passed

  Scenario: A data table with multiple columns is passed as a tibble
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/table.feature" with
      """
      Feature: Tables
        Scenario: Multi-column table
          Given a list of people
            | name  | age |
            | Alice | 30  |
            | Bob   | 25  |
          Then there are 2 people
          And the first person is "Alice"
      """
    And a file named "features/setup-steps.R" with
      """
      given("a list of people", function(table, context) {
        context$people <- table
      })
      then("there are {int} people", function(n, context) {
        expect_equal(nrow(context$people), n)
      })
      then("the first person is {string}", function(name, context) {
        expect_equal(context$people$name[[1]], name)
      })
      """
    When I run
      """
      test("features")
      """
    Then it passes
    And it has 2 passed

  Scenario: A table combined with parameter placeholders in step description
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/table.feature" with
      """
      Feature: Tables
        Scenario: Table with parameter
          Given 2 items in the basket
            | item   |
            | apple  |
            | banana |
          Then verify the basket has 2 items
      """
    And a file named "features/setup-steps.R" with
      """
      given("{int} items in the basket", function(count, table, context) {
        context$expected_count <- count
        context$items <- table$item
      })
      then("verify the basket has {int} items", function(n, context) {
        expect_equal(length(context$items), n)
        expect_equal(context$expected_count, n)
      })
      """
    When I run
      """
      test("features")
      """
    Then it passes
    And it has 2 passed
