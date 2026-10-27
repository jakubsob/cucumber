Feature: Running scenarios alongside testthat tests
  `run()` in a `tests/testthat/test-*.R` file runs the feature files in `tests/testthat`
  as part of the package's testthat tests, e.g. with `testthat::test_local()` or `devtools::test()`.
  It chooses what to run like `test()`, with `filter`, `features`, `tags` and `name`.
  testthat's reporter reports each scenario as a test of the test file that calls `run()`, and a
  failed step by its text and a warning, at its line of the feature file.
  Pass a `reporter` to `run()` to report the run with cucumber's reporter too.

  `run()` isn't supported in a parallel testthat run, with `Config/testthat/parallel: true`: it's an error.

  `run()` can also run feature files outside of a testthat run, like in the console. It then attaches
  testthat for the steps' expectations, runs every scenario and fails if one of them failed.
  Its step definitions and hooks are cleared when it returns.

  Background:
    Given a package
    And a file named "R/calculate.R" with
      """
      calculate <- function(x) x + 1
      """
    And a file named "tests/testthat/calculate.feature" with
      """
      Feature: Calculate
        Scenario: Adding one
          Given I calculate
          Then the result is 2
      """
    And a file named "tests/testthat/test-acceptance.R" with
      """
      run()
      """

  @rd
  Scenario: Scenarios run with the package's testthat tests
    Given a file named "tests/testthat/setup-steps.R" with
      """
      given("I calculate", function(context) {
        context$result <- calculate(1)
      })
      then("the result is {int}", function(n, context) {
        expect_equal(context$result, n)
      })
      """
    And a file named "tests/testthat/test-calculate.R" with
      """
      test_that("calculate adds one", {
        expect_equal(calculate(1), 2)
      })
      """
    When I run
      """
      testthat::test_local()
      """
    Then it passes
    And it ran "Scenario: Adding one"
    And it ran "calculate adds one"

  Scenario: Scenarios run when the test file that calls run() runs alone
    Like with `devtools::test_active_file()`, the setup files next to it are run too.

    Given a file named "tests/testthat/setup-steps.R" with
      """
      given("I calculate", function(context) {
        context$result <- calculate(1)
      })
      then("the result is {int}", function(n, context) {
        expect_equal(context$result, n)
      })
      """
    And a file named "tests/testthat/test-calculate.R" with
      """
      test_that("calculate adds one", {
        expect_equal(calculate(1), 2)
      })
      """
    When I run
      """
      pkgload::load_all(quiet = TRUE)
      testthat::test_file("tests/testthat/test-acceptance.R", reporter = "silent")
      """
    Then it passes
    And only these scenarios ran:
      | scenario   |
      | Adding one |

  Scenario: Step definitions sourced into an environment are passed with `test_local(env = )`
    Given a file named "tests/testthat/steps/steps.R" with
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
      source("tests/testthat/steps/steps.R", local = env)
      testthat::test_local(env = env)
      """
    Then it passes

  @rd
  Scenario Outline: run() chooses what to run like test(), with <argument>
    Given a file named "tests/testthat/other.feature" with
      """
      Feature: Other
        @slow
        Scenario: Not run
          Given I calculate
      """
    And a file named "tests/testthat/setup-steps.R" with
      """
      given("I calculate", function(context) {
        context$result <- calculate(1)
      })
      then("the result is {int}", function(n, context) {
        expect_equal(context$result, n)
      })
      """
    And a file named "tests/testthat/test-acceptance.R" with
      """
      run(<argument> = "<value>")
      """
    When I run
      """
      testthat::test_local()
      """
    Then only these scenarios ran:
      | scenario   |
      | Adding one |

    Examples:
      | argument | value             |
      | filter   | calculate         |
      | features | calculate.feature |
      | tags     | not @slow         |
      | name     | Adding one        |

  @rd
  Scenario: Each scenario is a test of the test file that calls run()
    Given a file named "tests/testthat/setup-steps.R" with
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
      testthat::test_local(reporter = "silent")
      """
    Then the results are of these files:
      | scenario   | file              |
      | Adding one | test-acceptance.R |

  Scenario: A test after run() in its test file isn't reported as a test of the last feature
    Given a file named "tests/testthat/setup-steps.R" with
      """
      given("I calculate", function(context) {
        context$result <- calculate(1)
      })
      then("the result is {int}", function(n, context) {
        expect_equal(context$result, n)
      })
      """
    And a file named "tests/testthat/test-acceptance.R" with
      """
      run()
      test_that("calculate adds one", {
        expect_equal(calculate(1), 2)
      })
      """
    When I run
      """
      testthat::test_local(reporter = "silent")
      """
    Then testthat reports the tests in these contexts:
      | test                 | context            |
      | Scenario: Adding one | Feature: Calculate |
      | calculate adds one   |                    |

  Scenario: testthat's reporter shows a step's warning at the line of the step
    Given a file named "tests/testthat/setup-steps.R" with
      """
      given("I calculate", function(context) {
        warning("calculate() is slow")
        context$result <- calculate(1)
      })
      then("the result is {int}", function(n, context) {
        expect_equal(context$result, n)
      })
      """
    When I run
      """
      testthat::test_local(reporter = "silent")
      """
    Then the scenarios have these warnings:
      | scenario   | warning             |
      | Adding one | calculate() is slow |
    And the scenarios warned at these locations:
      | scenario   | location            |
      | Adding one | calculate.feature:3 |

  Scenario: testthat's reporter shows the step that failed
    Given a file named "tests/testthat/setup-steps.R" with
      """
      given("I calculate", function(context) {
        context$result <- calculate(1)
      })
      then("the result is {int}", function(n, context) {
        expect_equal(context$result, 3)
      })
      """
    When I run
      """
      testthat::test_local(reporter = "summary", stop_on_failure = FALSE)
      """
    Then the output includes 'Step "the result is 2" failed'
    And the output doesn't include "1 scenario"

  @rd
  Scenario: testthat's reporter shows the line of the feature file where the step failed
    Given a file named "tests/testthat/setup-steps.R" with
      """
      given("I calculate", function(context) {
        context$result <- calculate(1)
      })
      then("the result is {int}", function(n, context) {
        expect_equal(context$result, 3)
      })
      """
    When I run
      """
      testthat::test_local(reporter = "progress", stop_on_failure = FALSE)
      """
    Then the scenarios failed at these locations:
      | scenario   | location            |
      | Adding one | calculate.feature:4 |

  Scenario: testthat's reporter shows a step's error like an error in a test
    Given a file named "tests/testthat/setup-steps.R" with
      """
      given("I calculate", function(context) {
        stop("can't calculate")
      })
      then("the result is {int}", function(n, context) {})
      """
    When I run
      """
      testthat::test_local(reporter = "summary", stop_on_failure = FALSE)
      """
    Then the errors are
      """
      [error] Scenario: Adding one
      Error: Step "I calculate" failed
      i Feature: calculate.feature
      i Scenario: Adding one
      i Step defined at: setup-steps.R:1
      Caused by error:
      ! can't calculate
      """

  Scenario: testthat's reporter shows the backtrace of a step's error
    Given a file named "tests/testthat/setup-steps.R" with
      """
      add_one <- function(x) stop("can't add one")
      given("I calculate", function(context) {
        context$result <- add_one(1)
      })
      """
    When I run
      """
      testthat::test_local(reporter = "summary", stop_on_failure = FALSE)
      """
    Then the output includes lines matching these patterns in order:
      """
      can't add one
      Backtrace:
      add_one\(1\)
      """

  Scenario: testthat's reporter shows an undefined step without a backtrace
    The step isn't code that ran, so there is no call to show.

    Given a file named "tests/testthat/setup-steps.R" with
      """
      given("I calculate", function(context) {
        context$result <- calculate(1)
      })
      """
    When I run
      """
      testthat::test_local(reporter = "summary", stop_on_failure = FALSE)
      """
    Then the output includes 'No step found for: "the result is 2"'
    And the output doesn't include "Backtrace"

  Scenario: run() runs outside of a testthat run
    The first run passes, and the second finds no step definition, as the first one cleared them when it returned.

    Given a file named "features/calculate.feature" with
      """
      Feature: Calculate
        Scenario: Adding one
          Then one plus one is 2
      """
    And a file named "features/steps.R" with
      """
      then("one plus one is {int}", function(n, context) {
        expect_equal(1 + 1, n)
      })
      """
    When I run outside of a testthat run
      """
      source("features/steps.R")
      run("features")
      run("features", strict = FALSE)
      """
    Then the scenarios have these results:
      | scenario   | status    |
      | Adding one | undefined |

  @rd
  Scenario: run() outside of a testthat run runs every scenario, and fails if one failed
    Steps can use testthat's expectations, as `run()` attaches testthat.

    Given a file named "features/calculate.feature" with
      """
      Feature: Calculate
        Scenario: Adding one
          Then one plus 1 is 2

        Scenario: Adding two
          Then one plus 2 is 4

        Scenario: Adding three
          Then one plus 3 is 4
      """
    And a file named "features/steps.R" with
      """
      then("one plus {int} is {int}", function(n, sum, context) {
        expect_equal(1 + n, sum)
      })
      """
    When I run outside of a testthat run and it fails
      """
      source("features/steps.R")
      run("features")
      """
    Then it fails with
      """
      Error:
      ! Test failures.
      """
    And the scenarios have these results:
      | scenario     | status |
      | Adding one   | passed |
      | Adding two   | failed |
      | Adding three | passed |

  Rule: Outside of a testthat run, run() reports the run with CucumberProgressReporter

    As there is no testthat reporter to show it. Pass `reporter = NULL` to report nothing.

    @rd
    Scenario: run() outside of a testthat run shows which step failed
      Given a file named "features/calculate.feature" with
        """
        Feature: Calculate
          Scenario: Adding one
            Then one plus 1 is 3
        """
      And a file named "features/steps.R" with
        """
        then("one plus {int} is {int}", function(n, sum, context) {
          expect_equal(1 + n, sum)
        })
        """
      When I run outside of a testthat run and it fails
        """
        source("features/steps.R")
        run("features")
        """
      Then the output includes these lines in order:
        """
        Scenario: Adding one
        x Then one plus 1 is 3
        Step "one plus 1 is 3" failed
        """

    Scenario: run() outside of a testthat run with reporter = NULL reports nothing
      Given a file named "features/calculate.feature" with
        """
        Feature: Calculate
          Scenario: Adding one
            Then one plus 1 is 2
        """
      And a file named "features/steps.R" with
        """
        then("one plus {int} is {int}", function(n, sum, context) {
          expect_equal(1 + n, sum)
        })
        """
      When I run outside of a testthat run
        """
        source("features/steps.R")
        run("features", reporter = NULL)
        """
      Then the scenarios have these results:
        | scenario   | status |
        | Adding one | passed |
      And the output doesn't include "Calculate"

  @rd
  Scenario: run() in a parallel testthat run is an error
    When I run
      """
      withr::with_envvar(
        c(TESTTHAT_IS_PARALLEL = "true"),
        testthat::test_local(reporter = "silent", stop_on_failure = FALSE)
      )
      """
    Then the errors are
      """
      [error]
      Error: `run()` isn't supported in a parallel testthat run.
      i Set `Config/testthat/parallel: false` in DESCRIPTION, or run the feature files with `cucumber::test()`.
      """

  Scenario: test() in a testthat file keeps the step definitions of the testthat run
    Given a file named "tests/testthat/setup-steps.R" with
      """
      given("I calculate", function(context) {
        context$result <- calculate(1)
      })
      then("the result is {int}", function(n, context) {
        expect_equal(context$result, n)
      })
      """
    And a file named "tests/acceptance/calculate.feature" with
      """
      Feature: Calculate
        Scenario: Adding one in tests/acceptance
          Given I add one to 1
          Then I get 2
      """
    And a file named "tests/acceptance/setup-steps.R" with
      """
      given("I add one to {int}", function(n, context) {
        context$result <- calculate(n)
      })
      then("I get {int}", function(n, context) {
        expect_equal(context$result, n)
      })
      """
    And a file named "tests/testthat/test-1-acceptance.R" with
      """
      cucumber::test("../acceptance", reporter = NULL)
      """
    When I run
      """
      testthat::test_local()
      """
    Then it passes
    And it ran "Scenario: Adding one"
