Feature: Data Tables
  A Data Table is a table under a step. The step definition gets it after the step's parameters.

  Background:
    Given a package

  Rule: A step definition gets the Data Table after the step's parameters

    @rd
    Scenario: A Data Table comes after the step's parameters
      Given a file named "features/table.feature" with
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

    Scenario: Data Table cells unescape \n, \| and \\
      Given a file named "features/table.feature" with
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

  Rule: In R, a Data Table is a tibble whose first row holds the column names

    @rd
    Scenario: A step receives a Data Table as a tibble
      Given a file named "features/table.feature" with
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
          expect_s3_class(table, "tbl_df")
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

    Scenario: Each column of a Data Table is a column of the tibble
      Given a file named "features/table.feature" with
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

    Scenario: Every cell is a character string
      Given a file named "features/table.feature" with
        """
        Feature: Tables
          Scenario: Numbers in a table
            Given a list of numbers
              | value | done |
              | 1     | TRUE |
            Then every cell is a string
        """
      And a file named "features/setup-steps.R" with
        """
        given("a list of numbers", function(table, context) {
          context$table <- table
        })
        then("every cell is a string", function(context) {
          expect_equal(context$table, tibble::tibble(value = "1", done = "TRUE"))
        })
        """
      When I run
        """
        test("features")
        """
      Then it passes

    Scenario: A Data Table with only a header row is a tibble with no rows
      Given a file named "features/table.feature" with
        """
        Feature: Tables
          Scenario: No people
            Given a list of people
              | name | age |
            Then there are no people
        """
      And a file named "features/setup-steps.R" with
        """
        given("a list of people", function(table, context) {
          context$people <- table
        })
        then("there are no people", function(context) {
          expect_equal(context$people, tibble::tibble(name = character(), age = character()))
        })
        """
      When I run
        """
        test("features")
        """
      Then it passes
