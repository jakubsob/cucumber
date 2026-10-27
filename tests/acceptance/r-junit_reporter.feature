@rd
Feature: JUnit reporter
  `CucumberJunitReporter` writes the JUnit XML report of a run when the run ends, even when it
  fails. CI services read it to show the results of the run.

  Each scenario is a test case, each example of an outline being one. Its class name is the feature's
  name and its name is the scenario's, after the rule's, followed by the name and number of the example.
  A scenario that passed, failed or was skipped is a passed, failed or skipped test case. A pending,
  undefined or ambiguous scenario is a failed one. Its steps and their results are the test case's output.
  A `before_all()` or `after_all()` hook that failed is a failed test case too, named after where it's defined.

  Background:
    Given a package

  Scenario: Each scenario is a test case, with its result
    A pending, undefined or ambiguous scenario is a failed test case.

    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket

        Scenario: Remove an item
          Given an empty basket
          When I remove an item

        Scenario: Pay
          Given an empty basket
          When I pay

        Scenario: Skip
          Given the basket isn't ready

        Scenario: Undefined
          When I empty the basket

        Scenario: Ambiguous
          When I check the basket

        Rule: Items are counted
          Scenario Outline: Add <n> items
            When I add <n> items

            Examples: Few
              | n |
              | 1 |
              | 2 |
      """
    And a file named "features/setup-steps.R" with
      """
      given("an empty basket", function(context) {})
      when("I remove an item", function(context) stop("The basket is empty"))
      when("I pay", function(context) pending())
      given("the basket isn't ready", function(context) skip_scenario("Not ready"))
      when("I add {int} items", function(n, context) {})
      when("I check the basket", function(context) {})
      when("I check the {word}", function(thing, context) {})
      """
    When I run
      """
      test("features", reporter = CucumberJunitReporter$new("report.xml"), stop_on_failure = FALSE)
      """
    Then the JUnit report "report.xml" has these test cases:
      | classname | name                                                        | result  | message                       |
      | Basket    | Add an item                                                 | passed  |                               |
      | Basket    | Remove an item                                              | failure | The basket is empty           |
      | Basket    | Pay                                                         | failure | Step "I pay" is pending: TODO |
      | Basket    | Skip                                                        | skipped |                               |
      | Basket    | Undefined                                                   | failure |                               |
      | Basket    | Ambiguous                                                   | failure |                               |
      | Basket    | Items are counted - Add <n> items - Few - #1.1: Add 1 items | passed  |                               |
      | Basket    | Items are counted - Add <n> items - Few - #1.2: Add 2 items | passed  |                               |

  Scenario: A failed before_all() or after_all() hook is a failed test case
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      before_all(function() {})
      after_all(function() stop("The server didn't stop"))
      given("an empty basket", function(context) {})
      """
    When I run
      """
      test("features", reporter = CucumberJunitReporter$new("report.xml"), stop_on_failure = FALSE)
      """
    Then the JUnit report "report.xml" has these test cases:
      | name            | result  | message                |
      | setup-steps.R:2 | failure | The server didn't stop |
      | Add an item     | passed  |                        |

  Scenario: A test case's output is its steps and their results
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Remove an item
          Given an empty basket
          When I remove an item
          Then the basket is empty
      """
    And a file named "features/setup-steps.R" with
      """
      given("an empty basket", function(context) {})
      when("I remove an item", function(context) stop("The basket is empty"))
      then("the basket is empty", function(context) {})
      """
    When I run
      """
      test("features", reporter = CucumberJunitReporter$new("report.xml"), stop_on_failure = FALSE)
      """
    Then the output of the test case "Remove an item" in the JUnit report "report.xml" is
      """
      Given an empty basket.......................................................passed
      When I remove an item.......................................................failed
      Then the basket is empty....................................................skipped
      """

  Scenario: An error with characters XML doesn't allow is written as the message of the failure
    An error can have characters XML doesn't allow, like the escape character of the colors of
    a terminal. Each is written as the text of its character reference, like `&#27;`, so the
    report is still XML that CI services read.

    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Remove an item
          When I remove an item
      """
    And a file named "features/setup-steps.R" with
      """
      when("I remove an item", function(context) stop("The basket is \033[31mempty\033[39m"))
      """
    When I run
      """
      test("features", reporter = CucumberJunitReporter$new("report.xml"), stop_on_failure = FALSE)
      """
    Then the JUnit report "report.xml" has these test cases:
      | name           | result  | message                               |
      | Remove an item | failure | The basket is &#27;[31mempty&#27;[39m |

  Scenario: The report is written to cucumber-junit.xml by default
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      given("an empty basket", function(context) {})
      """
    When I run
      """
      test("features", reporter = CucumberJunitReporter$new())
      """
    Then the JUnit report "cucumber-junit.xml" has these test cases:
      | name        | result |
      | Add an item | passed |
