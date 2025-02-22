# test: should run one feature

    Code
      testthat::test_dir(tests_path, reporter = testthat::ProgressReporter$new(
        show_praise = FALSE), stop_on_failure = FALSE)
    Output
      v | F W  S  OK | Context
      v |          2 | Feature: Guess the word
      == Results =====================================================================
      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 2 ]

# test: should run multiple features

    Code
      testthat::test_dir(tests_path, reporter = testthat::ProgressReporter$new(
        show_praise = FALSE), stop_on_failure = FALSE)
    Output
      v | F W  S  OK | Context
      v |          5 | Feature: Addition
      v |          2 | Feature: Guess the word
      == Results =====================================================================
      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 7 ]

# test: should run with box

    Code
      testthat::test_dir(tests_path, reporter = testthat::ProgressReporter$new(
        show_praise = FALSE), stop_on_failure = FALSE)
    Output
      v | F W  S  OK | Context
      v |          4 | Feature: Addition
      == Results =====================================================================
      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 4 ]

# test: should run with shinytest2

    Code
      testthat::test_dir(tests_path, reporter = testthat::ProgressReporter$new(
        show_praise = FALSE), stop_on_failure = FALSE)
    Output
      v | F W  S  OK | Context
      v |          2 | Feature: Formula display
      == Results =====================================================================
      
      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 2 ]

# test: should run a Scenario with Given, When, Then, And, But keywords

    Code
      testthat::test_dir(tests_path, reporter = testthat::ProgressReporter$new(
        show_praise = FALSE), stop_on_failure = FALSE)
    Output
      v | F W  S  OK | Context
      v |          3 | Feature: Addition
      == Results =====================================================================
      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 3 ]

# test: should run a Scenario with a Table

    Code
      testthat::test_dir(tests_path, reporter = testthat::ProgressReporter$new(
        show_praise = FALSE), stop_on_failure = FALSE)
    Output
      v | F W  S  OK | Context
      v |          1 | Feature: Column multiplication
      == Results =====================================================================
      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 1 ]

# test: should run a Scenario with a docstring

    Code
      testthat::test_dir(tests_path, reporter = testthat::ProgressReporter$new(
        show_praise = FALSE), stop_on_failure = FALSE)
    Output
      v | F W  S  OK | Context
      v |          1 | Feature: Docstrings
      == Results =====================================================================
      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 1 ]

# test: should run a Scenario with comments

    Code
      testthat::test_dir(tests_path, reporter = testthat::ProgressReporter$new(
        show_praise = FALSE), stop_on_failure = FALSE)
    Output
      v | F W  S  OK | Context
      v |          2 | Feature: Guess the word
      == Results =====================================================================
      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 2 ]

# test: should run before hook

    Code
      testthat::test_dir(tests_path, reporter = testthat::ProgressReporter$new(
        show_praise = FALSE), stop_on_failure = FALSE)
    Output
      v | F W  S  OK | Context
      v |          1 | Feature: Hooks
      == Results =====================================================================
      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 1 ]

# test: should run a Scenario with custom parameters

    Code
      testthat::test_dir(tests_path, reporter = testthat::ProgressReporter$new(
        show_praise = FALSE), stop_on_failure = FALSE)
    Output
      v | F W  S  OK | Context
      v |          2 | Feature: Addition
      == Results =====================================================================
      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 2 ]

# test: should run a Scenario with snapshot test

    Code
      testthat::test_dir(tests_path, reporter = testthat::ProgressReporter$new(
        show_praise = FALSE), stop_on_failure = FALSE)
    Output
      v | F W  S  OK | Context
      v |          1 | Feature: Snapshot
      == Results =====================================================================
      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 1 ]

# Scenario: 1 is bigger than 0

    Code
      source_files <- list.files(c("../../R", "./steps"), full.names = TRUE, pattern = ".R$")
      test_files <- list.files(".", full.names = TRUE, pattern = ".R$")
      covr::file_coverage(source_files, test_files)
    Message
      Coverage: 66.67%
      ../../R/get_bigger.R: 66.67%

# test: should work with custom steps loader

    Code
      testthat::test_dir(tests_path, reporter = testthat::ProgressReporter$new(
        show_praise = FALSE), stop_on_failure = FALSE)
    Output
      v | F W  S  OK | Context
      v |          1 | Feature: Add
      v |          1 | Feature: Multiply
      == Results =====================================================================
      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 2 ]

# test: should work with an arbitrary test directory

    Code
      testthat::test_dir(tests_path, reporter = testthat::ProgressReporter$new(
        show_praise = FALSE), stop_on_failure = FALSE)
    Output
      v | F W  S  OK | Context
      v |          2 | Feature: Guess the word
      == Results =====================================================================
      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 2 ]

# test: should report success with `testthat::test_dir`

    Code
      testthat::test_dir(tests_path, reporter = testthat::ProgressReporter$new(
        show_praise = FALSE), stop_on_failure = FALSE)
    Output
      v | F W  S  OK | Context
      v |          3 | Feature: Addition
      v |          2 | Feature: Guess the word
      == Results =====================================================================
      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 5 ]

# test: should report failure with `testthat::test_dir`

    Code
      testthat::test_dir(tests_path, reporter = testthat::ProgressReporter$new(
        show_praise = FALSE), stop_on_failure = FALSE)
    Output
      v | F W  S  OK | Context
      x | 2        1 | Feature: Addition
      --------------------------------------------------------------------------------
      Failure ('test-cucumber.R:1:1'): Scenario: Adding integer and float
      context$result (`actual`) not equal to `expected` (`expected`).
      `actual`: 2.1
      `expected`: 5.0
      Backtrace:
      x
      1. \-cucumber (local) call() at cucumber/R/parse_token.R:24:13
      2.   \-cucumber (local) x(context = context, ...)
      3.     \-global step(expected = 5L, ...)
      4.       \-testthat::expect_equal(context$result, expected) at ./steps/addition.R:7:3
      Failure ('test-cucumber.R:1:1'): Scenario: Adding float and float
      context$result (`actual`) not equal to `expected` (`expected`).
      `actual`: 2.2
      `expected`: 5.0
      Backtrace:
      x
      1. \-cucumber (local) call() at cucumber/R/parse_token.R:24:13
      2.   \-cucumber (local) x(context = context, ...)
      3.     \-global step(expected = 5L, ...)
      4.       \-testthat::expect_equal(context$result, expected) at ./steps/addition.R:7:3
      --------------------------------------------------------------------------------
      x | 1        1 | Feature: Guess the word
      --------------------------------------------------------------------------------
      Failure ('test-cucumber.R:1:1'): Scenario: Breaker joins a game
      nchar(context$word) (`actual`) not equal to `n` (`expected`).
      `actual`: 5
      `expected`: 6
      Backtrace:
      x
      1. \-cucumber (local) call() at cucumber/R/parse_token.R:24:13
      2.   \-cucumber (local) x(context = context, ...)
      3.     \-global step(n = 6L, ...)
      4.       \-testthat::expect_equal(nchar(context$word), n) at ./steps/guess_the_word.R:18:3
      --------------------------------------------------------------------------------
      == Results =====================================================================
      -- Failed tests ----------------------------------------------------------------
      Failure ('test-cucumber.R:1:1'): Scenario: Adding integer and float
      context$result (`actual`) not equal to `expected` (`expected`).
      `actual`: 2.1
      `expected`: 5.0
      Backtrace:
      x
      1. \-cucumber (local) call() at cucumber/R/parse_token.R:24:13
      2.   \-cucumber (local) x(context = context, ...)
      3.     \-global step(expected = 5L, ...)
      4.       \-testthat::expect_equal(context$result, expected) at ./steps/addition.R:7:3
      Failure ('test-cucumber.R:1:1'): Scenario: Adding float and float
      context$result (`actual`) not equal to `expected` (`expected`).
      `actual`: 2.2
      `expected`: 5.0
      Backtrace:
      x
      1. \-cucumber (local) call() at cucumber/R/parse_token.R:24:13
      2.   \-cucumber (local) x(context = context, ...)
      3.     \-global step(expected = 5L, ...)
      4.       \-testthat::expect_equal(context$result, expected) at ./steps/addition.R:7:3
      Failure ('test-cucumber.R:1:1'): Scenario: Breaker joins a game
      nchar(context$word) (`actual`) not equal to `n` (`expected`).
      `actual`: 5
      `expected`: 6
      Backtrace:
      x
      1. \-cucumber (local) call() at cucumber/R/parse_token.R:24:13
      2.   \-cucumber (local) x(context = context, ...)
      3.     \-global step(n = 6L, ...)
      4.       \-testthat::expect_equal(nchar(context$word), n) at ./steps/guess_the_word.R:18:3
      [ FAIL 3 | WARN 0 | SKIP 0 | PASS 2 ]

# test: should work with loading steps from setup files

    Code
      testthat::test_dir(tests_path, reporter = testthat::ProgressReporter$new(
        show_praise = FALSE), stop_on_failure = FALSE)
    Output
      v | F W  S  OK | Context
      v |          1 | Feature: Eating cucumbers
      == Results =====================================================================
      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 1 ]

# test: should work with Scenario Outline

    Code
      testthat::test_dir(tests_path, reporter = testthat::ProgressReporter$new(
        show_praise = FALSE), stop_on_failure = FALSE)
    Output
      v | F W  S  OK | Context
      v |          6 | Feature: Eating
      == Results =====================================================================
      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 6 ]

