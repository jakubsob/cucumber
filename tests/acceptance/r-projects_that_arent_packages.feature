Feature: Testing projects that aren't packages
  cucumber doesn't need a package. Step definitions can use code from `box` modules
  (https://github.com/klmr/box), or code sourced into an environment passed to `test(env = )`.

  Rule: Steps can use box modules

    Background:
      Given a file named "tests/acceptance/calculate.feature" with
        """
        Feature: Calculate
          Scenario: Adding one
            Given I add one to 1
            Then the result is 2

          Scenario: Adding two
            Given I add two to 1
            Then the result is 3
        """
      And a file named "src/calculate.R" with
        """
        #' @export
        add_one <- function(x) x + 1

        #' @export
        add_two <- function(x) x + 2
        """

    @rd
    Scenario: Steps can use a box module
      Given a file named "tests/acceptance/setup-steps.R" with
        """
        box::use(cucumber[given, then])
        box::use(../../src/calculate)

        given("I add one to {int}", function(x, context) {
          context$result <- calculate$add_one(x)
        })
        given("I add two to {int}", function(x, context) {
          context$result <- calculate$add_two(x)
        })
        then("the result is {int}", function(n, context) {
          expect_equal(context$result, n)
        })
        """
      When I run
        """
        box::purge_cache()
        test()
        """
      Then the scenarios have these results:
        | scenario   | status |
        | Adding one | passed |
        | Adding two | passed |

    Scenario: Steps can attach functions from a box module
      Given a file named "tests/acceptance/setup-steps.R" with
        """
        box::use(cucumber[given, then])
        box::use(../../src/calculate[add_one, add_two])

        given("I add one to {int}", function(x, context) {
          context$result <- add_one(x)
        })
        given("I add two to {int}", function(x, context) {
          context$result <- add_two(x)
        })
        then("the result is {int}", function(n, context) {
          expect_equal(context$result, n)
        })
        """
      When I run
        """
        box::purge_cache()
        test()
        """
      Then it passes
      And it has 2 passed

  Rule: Code sourced into an environment is available to steps

    @rd
    Scenario: Steps and code sourced into `env` are used by test()
      Given a file named "tests/calculate.feature" with
        """
        Feature: Calculate
          Scenario: Adding one
            Given I calculate
            Then the result is 2
        """
      And a file named "src/calculate.R" with
        """
        calculate <- function(x) x + 1
        """
      And a file named "tests/steps.R" with
        """
        given("I calculate", function(context) {
          context$result <- calculate(1)
        })
        then("the result is {int}", function(n, context) {
          expect_equal(context$result, n)
        })
        """
      When I run
        """
        env <- new.env()
        source("tests/steps.R", local = env)
        source("src/calculate.R", local = env)
        test("tests", env = env)
        """
      Then it passes
