Feature: Step definition arguments
  A step definition is a function. It gets the step's parameters, then its Data Table or Doc String,
  then `context`, in this order.

  Background:
    Given a package

  Scenario Outline: A step definition with the wrong number of arguments fails the step, <case>
    A step definition gets the step's parameters, then its Data Table or Doc String, then `context`.

    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add items
          When I add 3 items
            | name  |
            | apple |
      """
    And a file named "features/setup-steps.R" with
      """
      when("I add {int} items", <definition>)
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the errors are
      """
      [error] Scenario: Add items
      Error: Step "I add 3 items" failed
      i Feature: basket.feature:3
      i Scenario: Add items
      i Step defined at: setup-steps.R:1
      Caused by error:
      ! <message>
      i Use `function(int, data_table, context)`.
      """

    Examples:
      | case               | definition                            | message                                                     |
      | missing parameter  | function(context) {}                  | The step definition has 1 argument, but the step passes 3.  |
      | missing Data Table | function(n, context) {}               | The step definition has 2 arguments, but the step passes 3. |
      | extra argument     | function(n, table, extra, context) {} | The step definition has 4 arguments, but the step passes 3. |

  @rd
  Scenario Outline: A step definition without `context` as its last argument is an error, <case>
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add items
          When I add 3 items
      """
    And a file named "features/setup-steps.R" with
      """
      when("I add {int} items", <definition>)
      """
    When I run it and it fails
      """
      test("features")
      """
    Then it fails with
      """
      Error in `source_dir()`:
      ! Failed to evaluate './setup-steps.R'.
      Caused by error in `when()`:
      ! A step definition must have `context` as its last argument.
      i Use `function(n, context)`.
      """

    Examples:
      | case             | definition              |
      | missing context  | function(n) {}          |
      | context not last | function(context, n) {} |

  @rd
  Scenario: A step definition with `...` gets any number of arguments
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add items
          When I add 3 items
      """
    And a file named "features/setup-steps.R" with
      """
      when("I add {int} items", function(..., context) {
        expect_equal(list(...), list(3L))
      })
      """
    When I run
      """
      test("features")
      """
    Then it passes

  @rd
  Scenario: A step definition's arguments with a default value can be left out
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add items
          When I add 3 items
      """
    And a file named "features/setup-steps.R" with
      """
      when("I add {int} items", function(n, unit = "piece", context) {
        expect_equal(n, 3L)
        expect_equal(unit, "piece")
      })
      """
    When I run
      """
      test("features")
      """
    Then it passes
