Feature: Running feature files like testthat runs test files
  `test()` runs the feature files in `path` the way `testthat::test_dir()` runs test files:
  in `path` as the working directory, with the testthat edition and the package of `path` as
  `testthat::testing_package()`, the package `testthat::local_mocked_bindings()` mocks, after the
  `helper-*.R` and `setup-*.R` files, and before the `teardown-*.R` files. Steps can use
  testthat's expectations, and `testthat::is_testing()` is `TRUE` in them. What the setup files and
  steps defer to `testthat::teardown_env()` runs when `test()` ends. Each feature file is the
  file of its scenarios' results. Outside of a testthat run, like in the console, `test()` sets
  `NOT_CRAN` to `"true"`, like `testthat::test_local()`, so snapshots are checked. In a testthat
  run or in R CMD check, `NOT_CRAN` is left as it is, so `skip_on_cran()` still skips on CRAN.
  `skip()` in a `before_all()` hook skips every scenario, like `skip()` at the top of a test file skips its tests.
  `test()` writes no test file into `path`, and doesn't run its `test-*.R` files: they can test the
  code the steps use, with `testthat::test_dir()`.

  Background:
    Given a package
    And a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Adding an apple
          Given an empty basket
          When I add an apple
          Then the basket has 1 item
      """
    And a file named "features/setup-steps.R" with
      """
      given("an empty basket", function(context) {
        context$items <- 0
      })
      when("I add an apple", function(context) {
        context$items <- context$items + 1
      })
      then("the basket has {int} item(s)", function(n, context) {
        expect_equal(context$items, n)
      })
      """

  Scenario: test() writes no test file into the directory of the feature files
    Given a file named "features/setup-files.R" with
      """
      before(function(context, scenario) {
        writeLines(dir(all.files = TRUE, no.. = TRUE), "../files-during-run.txt")
      })
      """
    When I run
      """
      test("features")
      """
    Then the file "files-during-run.txt" has these lines:
      """
      basket.feature
      setup-files.R
      setup-steps.R
      """

  Scenario: test() doesn't run the test files next to the feature files
    Given a file named "features/test-steps.R" with
      """
      writeLines("ran", "../test-file-ran.txt")
      test_that("the steps work", expect_true(TRUE))
      """
    When I run
      """
      test("features")
      """
    Then only these scenarios ran:
      | scenario        |
      | Adding an apple |
    And there is no file "test-file-ran.txt"

  Scenario: Steps run in the directory of the feature files
    Given a file named "features/basket.txt" with
      """
      apple
      """
    And a file named "features/setup-basket.R" with
      """
      given("the basket in basket.txt", function(context) {
        context$items <- length(readLines("basket.txt"))
      })
      """
    And a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Reading the basket
          Given the basket in basket.txt
          Then the basket has 1 item
      """
    When I run
      """
      test("features")
      """
    Then the scenarios have these results:
      | scenario           | status |
      | Reading the basket | passed |

  Scenario: testthat::is_testing() is TRUE in steps
    Given a file named "features/setup-testing.R" with
      """
      then("tests are running", function(context) {
        expect_true(testthat::is_testing())
      })
      """
    And a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Checking that tests are running
          Then tests are running
      """
    When I run
      """
      test("features")
      """
    Then the scenarios have these results:
      | scenario                        | status |
      | Checking that tests are running | passed |

  Scenario: Steps use the testthat edition of the package
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      Config/testthat/edition: 3
      """
    And a file named "features/setup-edition.R" with
      """
      then("the testthat edition is {int}", function(n, context) {
        expect_equal(testthat::edition_get(), n)
      })
      """
    And a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Checking the edition
          Then the testthat edition is 3
      """
    When I run
      """
      test("features")
      """
    Then the scenarios have these results:
      | scenario             | status |
      | Checking the edition | passed |

  Scenario: testthat::testing_package() is the package of the feature files
    Given a file named "features/setup-package.R" with
      """
      then("the package under test is {string}", function(name, context) {
        expect_equal(testthat::testing_package(), name)
      })
      """
    And a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Checking the package
          Then the package under test is "example"
      """
    When I run
      """
      test("features")
      """
    Then the scenarios have these results:
      | scenario              | status |
      | Checking the package  | passed |

  Scenario: Helper files aren't run with `load_helpers = FALSE`
    Given a file named "features/helper-basket.R" with
      """
      writeLines("helper", "../helper-ran.txt")
      """
    When I run
      """
      test("features", load_helpers = FALSE)
      """
    Then there is no file "helper-ran.txt"

  Scenario: Teardown files run after the scenarios
    Given a file named "features/setup-log.R" with
      """
      after(function(context, scenario) cat("after scenario\n", file = "../log.txt", append = TRUE))
      """
    And a file named "features/teardown-log.R" with
      """
      cat("teardown\n", file = "../log.txt", append = TRUE)
      """
    When I run
      """
      test("features")
      """
    Then the file "log.txt" has these lines:
      """
      after scenario
      teardown
      """

  Scenario: What setup files and steps defer to testthat::teardown_env() runs when test() ends
    Given a file named "features/setup-log.R" with
      """
      withr::defer(cat("setup file deferred\n", file = "../log.txt", append = TRUE), teardown_env())
      after(function(context, scenario) cat("after scenario\n", file = "../log.txt", append = TRUE))
      then("the basket is put away when the tests end", function(context) {
        withr::defer(cat("step deferred\n", file = "../log.txt", append = TRUE), teardown_env())
        succeed()
      })
      """
    And a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Putting the basket away
          Then the basket is put away when the tests end
      """
    When I run outside of a testthat run
      """
      test("features")
      """
    Then the scenarios have these results:
      | scenario                | status |
      | Putting the basket away | passed |
    And the file "log.txt" has these lines:
      """
      after scenario
      step deferred
      setup file deferred
      """

  Scenario: skip() in a before_all() hook skips every scenario
    Given a file named "features/setup-skip.R" with
      """
      before_all(function() skip("No database"))
      """
    When I run
      """
      test("features")
      """
    Then the scenarios have these results:
      | scenario        | status  |
      | Adding an apple | skipped |
    And the results are skipped with "No database"

  Scenario: A failed scenario is an error, unless `stop_on_failure = FALSE`
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Adding an apple
          Given an empty basket
          Then the basket has 1 item
      """
    When I run it and it fails
      """
      test("features")
      """
    Then it fails with "Test failures"
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the scenarios have these results:
      | scenario        | status |
      | Adding an apple | failed |

  Scenario: A warning is an error with `stop_on_warning = TRUE`
    Given a file named "features/setup-warning.R" with
      """
      then("the basket is heavy", function(context) {
        warning("The basket is heavy")
      })
      """
    And a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Lifting the basket
          Then the basket is heavy
      """
    When I run it and it fails
      """
      test("features", stop_on_warning = TRUE)
      """
    Then it fails with "Tests generated warnings"

  Scenario: Each feature file is the file of its scenarios' results
    Given a file named "features/checkout/payment.feature" with
      """
      Feature: Payment
        Scenario: Paying for an apple
          Given an empty basket
          When I add an apple
          Then the basket has 1 item
      """
    When I run
      """
      test("features")
      """
    Then the results are of these files:
      | scenario            | file                     |
      | Adding an apple     | basket.feature           |
      | Paying for an apple | checkout/payment.feature |

  Scenario: The error that stopped the run is shown with `stop_on_failure = TRUE`
    When I run it and it fails
      """
      test("features", reporter = NULL, filter = "checkout")
      """
    Then it fails with "Test failures"
    And it fails with "No feature files found"

  Scenario: test() in a testthat run, like in R CMD check, leaves NOT_CRAN as it is
    Given a file named "tests/acceptance/basket.feature" with
      """
      Feature: Basket
        Scenario: Checking where tests run
          Then NOT_CRAN is saved
      """
    And a file named "tests/acceptance/setup-steps.R" with
      """
      then("NOT_CRAN is saved", function(context) {
        writeLines(paste0("NOT_CRAN=", Sys.getenv("NOT_CRAN")), "../../not-cran.txt")
      })
      """
    And a file named "tests/testthat/test-acceptance.R" with
      """
      cucumber::test("../acceptance", reporter = NULL)
      """
    When I run
      """
      withr::with_envvar(c(NOT_CRAN = NA), testthat::test_dir("tests/testthat", reporter = "silent"))
      """
    Then the file "not-cran.txt" has these lines:
      """
      NOT_CRAN=
      """

  Scenario: test() in R CMD check leaves NOT_CRAN as it is
    Given a file named "tests/acceptance/basket.feature" with
      """
      Feature: Basket
        Scenario: Checking where tests run
          Then NOT_CRAN is saved
      """
    And a file named "tests/acceptance/setup-steps.R" with
      """
      then("NOT_CRAN is saved", function(context) {
        writeLines(paste0("NOT_CRAN=", Sys.getenv("NOT_CRAN")), "../../not-cran.txt")
      })
      """
    When I run
      """
      withr::with_envvar(
        c(NOT_CRAN = NA, TESTTHAT = NA, `_R_CHECK_PACKAGE_NAME_` = "example"),
        test("tests/acceptance", reporter = NULL)
      )
      """
    Then the file "not-cran.txt" has these lines:
      """
      NOT_CRAN=
      """
