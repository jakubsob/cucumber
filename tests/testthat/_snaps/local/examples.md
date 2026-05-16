# test / should run one feature

    Code
      test(tests_path, reporter = testthat::ProgressReporter$new(show_praise = FALSE),
      stop_on_failure = FALSE, ...)
    Output
      v | F W  S  OK | Context
      
      v |          2 | Feature: Guess the word
      
      == Results =====================================================================
      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 2 ]

# test / should run multiple features

    Code
      test(tests_path, reporter = testthat::ProgressReporter$new(show_praise = FALSE),
      stop_on_failure = FALSE, ...)
    Output
      v | F W  S  OK | Context
      
      v |          5 | Feature: Addition
      
      v |          2 | Feature: Guess the word
      
      == Results =====================================================================
      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 7 ]

# test / should run with box

    Code
      test(tests_path, reporter = testthat::ProgressReporter$new(show_praise = FALSE),
      stop_on_failure = FALSE, ...)
    Output
      v | F W  S  OK | Context
      
      v |          4 | Feature: Addition
      
      == Results =====================================================================
      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 4 ]

# test / should run with shinytest2

    Code
      test(tests_path, reporter = testthat::ProgressReporter$new(show_praise = FALSE),
      stop_on_failure = FALSE, ...)
    Output
      v | F W  S  OK | Context
      
      v |          2 | Feature: Formula display
      
      == Results =====================================================================
      
      
      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 2 ]

# test / should run a Scenario with Given, When, Then, And, But keywords

    Code
      test(tests_path, reporter = testthat::ProgressReporter$new(show_praise = FALSE),
      stop_on_failure = FALSE, ...)
    Output
      v | F W  S  OK | Context
      
      v |          3 | Feature: Addition
      
      == Results =====================================================================
      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 3 ]

# test / should run a Scenario with a Table

    Code
      test(tests_path, reporter = testthat::ProgressReporter$new(show_praise = FALSE),
      stop_on_failure = FALSE, ...)
    Output
      v | F W  S  OK | Context
      
      v |          1 | Feature: Column multiplication
      
      == Results =====================================================================
      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 1 ]

# test / should run a Scenario with a docstring

    Code
      test(tests_path, reporter = testthat::ProgressReporter$new(show_praise = FALSE),
      stop_on_failure = FALSE, ...)
    Output
      v | F W  S  OK | Context
      
      v |          1 | Feature: Docstrings
      
      == Results =====================================================================
      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 1 ]

# test / should run a Scenario with comments

    Code
      test(tests_path, reporter = testthat::ProgressReporter$new(show_praise = FALSE),
      stop_on_failure = FALSE, ...)
    Output
      v | F W  S  OK | Context
      
      v |          2 | Feature: Guess the word
      
      == Results =====================================================================
      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 2 ]

# test / should run before and after hooks

    Code
      test(tests_path, reporter = testthat::ProgressReporter$new(show_praise = FALSE),
      stop_on_failure = FALSE, ...)
    Output
      v | F W  S  OK | Context
      
      v |   2      1 | Feature: Hooks
      --------------------------------------------------------------------------------
      Warning ('test-__cucumber__.R:1:1'): Scenario: Before hook is executed
      Warning in before hook.
      Backtrace:
          x
       1. \-before(.context, pickle$name) at cucumber/R/execute_pickles.R:39:5
      
      Warning ('test-__cucumber__.R:1:1'): Scenario: Before hook is executed
      Warning in after hook.
      Backtrace:
          x
       1. \-after(.context, pickle$name)
      --------------------------------------------------------------------------------
      
      == Results =====================================================================
      [ FAIL 0 | WARN 2 | SKIP 0 | PASS 1 ]

# test / should run a Scenario with custom parameters

    Code
      test(tests_path, reporter = testthat::ProgressReporter$new(show_praise = FALSE),
      stop_on_failure = FALSE, ...)
    Output
      v | F W  S  OK | Context
      
      v |          2 | Feature: Addition
      
      == Results =====================================================================
      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 2 ]

# test / should run a Scenario with snapshot test

    Code
      test(tests_path, reporter = testthat::ProgressReporter$new(show_praise = FALSE),
      stop_on_failure = FALSE, ...)
    Output
      v | F W  S  OK | Context
      
      v |          1 | Feature: Snapshot
      
      == Results =====================================================================
      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 1 ]

# test / should work with an arbitrary test directory

    Code
      test(tests_path, reporter = testthat::ProgressReporter$new(show_praise = FALSE),
      stop_on_failure = FALSE, ...)
    Output
      v | F W  S  OK | Context
      
      v |          2 | Feature: Guess the word
      
      == Results =====================================================================
      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 2 ]

# test / should report success with `testthat::test_dir`

    Code
      test(tests_path, reporter = testthat::ProgressReporter$new(show_praise = FALSE),
      stop_on_failure = FALSE, ...)
    Output
      v | F W  S  OK | Context
      
      v |          3 | Feature: Addition
      
      v |          2 | Feature: Guess the word
      
      == Results =====================================================================
      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 5 ]

# test / should work with loading steps from setup files

    Code
      test(tests_path, reporter = testthat::ProgressReporter$new(show_praise = FALSE),
      stop_on_failure = FALSE, ...)
    Output
      v | F W  S  OK | Context
      
      v |          1 | Feature: Eating cucumbers
      
      == Results =====================================================================
      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 1 ]

# test / should work with Scenario Outline

    Code
      test(tests_path, reporter = testthat::ProgressReporter$new(show_praise = FALSE),
      stop_on_failure = FALSE, ...)
    Output
      v | F W  S  OK | Context
      
      v |          6 | Feature: Eating
      
      == Results =====================================================================
      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 6 ]

# test / shouldn't run testthat test files

    Code
      test(tests_path, reporter = testthat::ProgressReporter$new(show_praise = FALSE),
      stop_on_failure = FALSE, ...)
    Output
      v | F W  S  OK | Context
      
      v |          2 | Feature: Guess the word
      
      == Results =====================================================================
      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 2 ]

# test / should work with testthat filtering

    Code
      test(tests_path, reporter = testthat::ProgressReporter$new(show_praise = FALSE),
      stop_on_failure = FALSE, ...)
    Output
      v | F W  S  OK | Context
      
      v |          2 | Feature: Guess the word
      
      == Results =====================================================================
      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 2 ]

# test / should run tests with custom loading of steps and support code

    Code
      .test()
    Output
      v | F W  S  OK | Context
      
      v |          2 | Feature: Guess the word
      
      == Results =====================================================================
      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 2 ]

