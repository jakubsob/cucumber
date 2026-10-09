Feature: Step definition arguments
  A step definition is a function. It gets the step's parameters, then its data table or doc string,
  then `context`, in this order.

  Background:
    Given a package

  Scenario Outline: A step definition with the wrong number of arguments fails the step, <case>
    A step definition gets the step's parameters, then its data table or doc string, then `context`.

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
    Then it has 1 errors
    And the error message includes "<message>"
    And the error message includes "Use `function(int, data_table, context)`."

    Examples:
      | case                 | definition                               | message                                                    |
      | missing parameter    | function(context) {}                    | The step definition has 1 argument, but the step passes 3.  |
      | missing data table   | function(n, context) {}                 | The step definition has 2 arguments, but the step passes 3. |
      | extra argument       | function(n, table, extra, context) {}   | The step definition has 4 arguments, but the step passes 3. |

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
