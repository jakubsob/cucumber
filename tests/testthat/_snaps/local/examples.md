# test: should run one feature

    Code
      cucumber::test(tests_path, reporter = testthat::ProgressReporter$new(
        show_praise = FALSE), stop_on_failure = FALSE, ...)
    Output
      v | F W  S  OK | Context
      v |          2 | Feature: Guess the word
      == Results =====================================================================
      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 2 ]

# test: should run multiple features

    Code
      cucumber::test(tests_path, reporter = testthat::ProgressReporter$new(
        show_praise = FALSE), stop_on_failure = FALSE, ...)
    Output
      v | F W  S  OK | Context
      v |          5 | Feature: Addition
      v |          2 | Feature: Guess the word
      == Results =====================================================================
      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 7 ]

# test: should run with box

    Code
      cucumber::test(tests_path, reporter = testthat::ProgressReporter$new(
        show_praise = FALSE), stop_on_failure = FALSE, ...)
    Output
      v | F W  S  OK | Context
      v |          4 | Feature: Addition
      == Results =====================================================================
      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 4 ]

# test: should run with shinytest2

    Code
      cucumber::test(tests_path, reporter = testthat::ProgressReporter$new(
        show_praise = FALSE), stop_on_failure = FALSE, ...)
    Output
      v | F W  S  OK | Context
      v |          2 | Feature: Formula display
      == Results =====================================================================
      
      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 2 ]

# test: should run a Scenario with Given, When, Then, And, But keywords

    Code
      cucumber::test(tests_path, reporter = testthat::ProgressReporter$new(
        show_praise = FALSE), stop_on_failure = FALSE, ...)
    Output
      v | F W  S  OK | Context
      v |          3 | Feature: Addition
      == Results =====================================================================
      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 3 ]

# test: should run a Scenario with a Table

    Code
      cucumber::test(tests_path, reporter = testthat::ProgressReporter$new(
        show_praise = FALSE), stop_on_failure = FALSE, ...)
    Output
      v | F W  S  OK | Context
      v |          1 | Feature: Column multiplication
      == Results =====================================================================
      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 1 ]

# test: should run a Scenario with a docstring

    Code
      cucumber::test(tests_path, reporter = testthat::ProgressReporter$new(
        show_praise = FALSE), stop_on_failure = FALSE, ...)
    Output
      v | F W  S  OK | Context
      v |          1 | Feature: Docstrings
      == Results =====================================================================
      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 1 ]

# test: should run a Scenario with comments

    Code
      cucumber::test(tests_path, reporter = testthat::ProgressReporter$new(
        show_praise = FALSE), stop_on_failure = FALSE, ...)
    Output
      v | F W  S  OK | Context
      v |          2 | Feature: Guess the word
      == Results =====================================================================
      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 2 ]

# test: should run before and after hooks

    Code
      cucumber::test(tests_path, reporter = testthat::ProgressReporter$new(
        show_praise = FALSE), stop_on_failure = FALSE, ...)
    Output
      v | F W  S  OK | Context
      v |   2      1 | Feature: Hooks
      --------------------------------------------------------------------------------
      Warning ('test-__cucumber__.R:2:1'): Scenario: Before hook is executed
      Warning in before hook.
      Backtrace:
      x
      1. \-before(.context, token$value) at cucumber/R/parse_token.R:22:11
      Warning ('test-__cucumber__.R:2:1'): Scenario: Before hook is executed
      Warning in after hook.
      Backtrace:
      x
      1. \-after(.context, token$value)
      --------------------------------------------------------------------------------
      == Results =====================================================================
      [ FAIL 0 | WARN 2 | SKIP 0 | PASS 1 ]

# test: should run after hook, even after error in step

    Code
      cucumber::test(tests_path, reporter = testthat::ProgressReporter$new(
        show_praise = FALSE), stop_on_failure = FALSE, ...)
    Output
      v | F W  S  OK | Context
      x | 1 2      0 | Feature: Hooks
      --------------------------------------------------------------------------------
      Warning ('test-__cucumber__.R:2:1'): Scenario: After hook is executed even when a step throws an error
      Warning in before hook.
      Backtrace:
      x
      1. \-before(.context, token$value) at cucumber/R/parse_token.R:22:11
      Error ('test-__cucumber__.R:2:1'): Scenario: After hook is executed even when a step throws an error
      Error in `(function (context)
      {
      stop("Unexpected error!")
      })(context = <environment>)`: Unexpected error!
      Backtrace:
      x
      1. +-rlang::exec(step, !!!args, context = .context) at cucumber/R/parse_token.R:28:13
      2. \-`<fn>`(context = `<env>`)
      Warning ('test-__cucumber__.R:2:1'): Scenario: After hook is executed even when a step throws an error
      Warning in after hook, even after error in a step.
      Backtrace:
      x
      1. \-after(.context, token$value)
      --------------------------------------------------------------------------------
      == Results =====================================================================
      -- Failed tests ----------------------------------------------------------------
      Error ('test-__cucumber__.R:2:1'): Scenario: After hook is executed even when a step throws an error
      Error in `(function (context)
      {
      stop("Unexpected error!")
      })(context = <environment>)`: Unexpected error!
      Backtrace:
      x
      1. +-rlang::exec(step, !!!args, context = .context) at cucumber/R/parse_token.R:28:13
      2. \-`<fn>`(context = `<env>`)
      [ FAIL 1 | WARN 2 | SKIP 0 | PASS 0 ]

# test: should run a Scenario with custom parameters

    Code
      cucumber::test(tests_path, reporter = testthat::ProgressReporter$new(
        show_praise = FALSE), stop_on_failure = FALSE, ...)
    Output
      v | F W  S  OK | Context
      v |          2 | Feature: Addition
      == Results =====================================================================
      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 2 ]

# test: should run a Scenario with snapshot test

    Code
      cucumber::test(tests_path, reporter = testthat::ProgressReporter$new(
        show_praise = FALSE), stop_on_failure = FALSE, ...)
    Output
      v | F W  S  OK | Context
      v |          1 | Feature: Snapshot
      == Results =====================================================================
      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 1 ]

# test: should work with an arbitrary test directory

    Code
      cucumber::test(tests_path, reporter = testthat::ProgressReporter$new(
        show_praise = FALSE), stop_on_failure = FALSE, ...)
    Output
      v | F W  S  OK | Context
      v |          2 | Feature: Guess the word
      == Results =====================================================================
      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 2 ]

# test: should report success with `testthat::test_dir`

    Code
      cucumber::test(tests_path, reporter = testthat::ProgressReporter$new(
        show_praise = FALSE), stop_on_failure = FALSE, ...)
    Output
      v | F W  S  OK | Context
      v |          3 | Feature: Addition
      v |          2 | Feature: Guess the word
      == Results =====================================================================
      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 5 ]

# test: should report failure with `testthat::test_dir`

    Code
      cucumber::test(tests_path, reporter = testthat::ProgressReporter$new(
        show_praise = FALSE), stop_on_failure = FALSE, ...)
    Output
      v | F W  S  OK | Context
      x | 2        1 | Feature: Addition
      --------------------------------------------------------------------------------
      Failure ('test-__cucumber__.R:2:1'): Scenario: Adding integer and float
      context$result (`actual`) not equal to `expected` (`expected`).
      `actual`: 2.1
      `expected`: 5.0
      Backtrace:
      x
      1. +-rlang::exec(step, !!!args, context = .context) at cucumber/R/parse_token.R:28:13
      2. \-`<fn>`(expected = 5L, context = `<env>`)
      3.   \-testthat::expect_equal(context$result, expected) at tests/acceptance/setup-steps-addition.R:7:3
      Failure ('test-__cucumber__.R:2:1'): Scenario: Adding float and float
      context$result (`actual`) not equal to `expected` (`expected`).
      `actual`: 2.2
      `expected`: 5.0
      Backtrace:
      x
      1. +-rlang::exec(step, !!!args, context = .context) at cucumber/R/parse_token.R:28:13
      2. \-`<fn>`(expected = 5L, context = `<env>`)
      3.   \-testthat::expect_equal(context$result, expected) at tests/acceptance/setup-steps-addition.R:7:3
      --------------------------------------------------------------------------------
      x | 1        1 | Feature: Guess the word
      --------------------------------------------------------------------------------
      Failure ('test-__cucumber__.R:2:1'): Scenario: Breaker joins a game
      nchar(context$word) (`actual`) not equal to `n` (`expected`).
      `actual`: 5
      `expected`: 6
      Backtrace:
      x
      1. +-rlang::exec(step, !!!args, context = .context) at cucumber/R/parse_token.R:28:13
      2. \-`<fn>`(n = 6L, context = `<env>`)
      3.   \-testthat::expect_equal(nchar(context$word), n) at tests/acceptance/setup-steps-guess_the_word.R:18:3
      --------------------------------------------------------------------------------
      == Results =====================================================================
      -- Failed tests ----------------------------------------------------------------
      Failure ('test-__cucumber__.R:2:1'): Scenario: Adding integer and float
      context$result (`actual`) not equal to `expected` (`expected`).
      `actual`: 2.1
      `expected`: 5.0
      Backtrace:
      x
      1. +-rlang::exec(step, !!!args, context = .context) at cucumber/R/parse_token.R:28:13
      2. \-`<fn>`(expected = 5L, context = `<env>`)
      3.   \-testthat::expect_equal(context$result, expected) at tests/acceptance/setup-steps-addition.R:7:3
      Failure ('test-__cucumber__.R:2:1'): Scenario: Adding float and float
      context$result (`actual`) not equal to `expected` (`expected`).
      `actual`: 2.2
      `expected`: 5.0
      Backtrace:
      x
      1. +-rlang::exec(step, !!!args, context = .context) at cucumber/R/parse_token.R:28:13
      2. \-`<fn>`(expected = 5L, context = `<env>`)
      3.   \-testthat::expect_equal(context$result, expected) at tests/acceptance/setup-steps-addition.R:7:3
      Failure ('test-__cucumber__.R:2:1'): Scenario: Breaker joins a game
      nchar(context$word) (`actual`) not equal to `n` (`expected`).
      `actual`: 5
      `expected`: 6
      Backtrace:
      x
      1. +-rlang::exec(step, !!!args, context = .context) at cucumber/R/parse_token.R:28:13
      2. \-`<fn>`(n = 6L, context = `<env>`)
      3.   \-testthat::expect_equal(nchar(context$word), n) at tests/acceptance/setup-steps-guess_the_word.R:18:3
      [ FAIL 3 | WARN 0 | SKIP 0 | PASS 2 ]

# test: should work with loading steps from setup files

    Code
      cucumber::test(tests_path, reporter = testthat::ProgressReporter$new(
        show_praise = FALSE), stop_on_failure = FALSE, ...)
    Output
      v | F W  S  OK | Context
      v |          1 | Feature: Eating cucumbers
      == Results =====================================================================
      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 1 ]

# test: should work with Scenario Outline

    Code
      cucumber::test(tests_path, reporter = testthat::ProgressReporter$new(
        show_praise = FALSE), stop_on_failure = FALSE, ...)
    Output
      v | F W  S  OK | Context
      v |          6 | Feature: Eating
      == Results =====================================================================
      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 6 ]

# test: shouldn't run testthat test files

    Code
      cucumber::test(tests_path, reporter = testthat::ProgressReporter$new(
        show_praise = FALSE), stop_on_failure = FALSE, ...)
    Output
      v | F W  S  OK | Context
      v |          2 | Feature: Guess the word
      == Results =====================================================================
      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 2 ]

# test: should work with testthat filtering

    Code
      cucumber::test(tests_path, reporter = testthat::ProgressReporter$new(
        show_praise = FALSE), stop_on_failure = FALSE, ...)
    Output
      v | F W  S  OK | Context
      v |          2 | Feature: Guess the word
      == Results =====================================================================
      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 2 ]

# test: should throw an error if no test files are found

    Code
      cucumber::test(tests_path, reporter = testthat::ProgressReporter$new(
        show_praise = FALSE), stop_on_failure = FALSE, ...)
    Output
      v | F W  S  OK | Context
      x | 1        0 | __cucumber__
      --------------------------------------------------------------------------------
      Error ('test-__cucumber__.R:2:1'): (code run outside of `test_that()`)
      Error in `cucumber::run(".", "this_feature_doesnt_exist")`: No feature files found
      Backtrace:
      x
      1. \-cucumber::run(".", "this_feature_doesnt_exist") at test-__cucumber__.R:2:1
      2.   \-rlang::abort("No feature files found") at cucumber/R/test.R:17:5
      --------------------------------------------------------------------------------
      == Results =====================================================================
      -- Failed tests ----------------------------------------------------------------
      Error ('test-__cucumber__.R:2:1'): (code run outside of `test_that()`)
      Error in `cucumber::run(".", "this_feature_doesnt_exist")`: No feature files found
      Backtrace:
      x
      1. \-cucumber::run(".", "this_feature_doesnt_exist") at test-__cucumber__.R:2:1
      2.   \-rlang::abort("No feature files found") at cucumber/R/test.R:17:5
      [ FAIL 1 | WARN 0 | SKIP 0 | PASS 0 ]

# test: should run tests with custom loading of steps and support code

    Code
      .test()
    Output
      v | F W  S  OK | Context
      v |          2 | Feature: Guess the word
      == Results =====================================================================
      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 2 ]

