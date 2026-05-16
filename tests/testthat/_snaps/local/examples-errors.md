# test / error handling / should throw an error if no steps are defined

    Code
      test(tests_path, reporter = testthat::ProgressReporter$new(show_praise = FALSE),
      stop_on_failure = FALSE, ...)
    Output
      v | F W  S  OK | Context
      
      x | 1        0 | Feature: Add
      --------------------------------------------------------------------------------
      Error ('test-__cucumber__.R:1:1'): (code run outside of `test_that()`)
      Error in `match_single_step(step, steps, parameters)`: No step found for: "I have 1"
      i Add a step definition:
        given("I have {int}", function(int, context) {
        pending()
      })
      --------------------------------------------------------------------------------
      
      == Results =====================================================================
      -- Failed tests ----------------------------------------------------------------
      Error ('test-__cucumber__.R:1:1'): (code run outside of `test_that()`)
      Error in `match_single_step(step, steps, parameters)`: No step found for: "I have 1"
      i Add a step definition:
        given("I have {int}", function(int, context) {
        pending()
      })
      
      [ FAIL 1 | WARN 0 | SKIP 0 | PASS 0 ]

# test / error handling / should throw an error if no test files are found

    Code
      test(tests_path, reporter = testthat::ProgressReporter$new(show_praise = FALSE),
      stop_on_failure = FALSE, ...)
    Output
      v | F W  S  OK | Context
      
      x | 1        0 | __cucumber__
      --------------------------------------------------------------------------------
      Error ('test-__cucumber__.R:1:1'): (code run outside of `test_that()`)
      Error in `cucumber::run(".", filter = "this_feature_doesnt_exist")`: No feature files found.
      i Add `.feature` files describing your scenarios.
      --------------------------------------------------------------------------------
      
      == Results =====================================================================
      -- Failed tests ----------------------------------------------------------------
      Error ('test-__cucumber__.R:1:1'): (code run outside of `test_that()`)
      Error in `cucumber::run(".", filter = "this_feature_doesnt_exist")`: No feature files found.
      i Add `.feature` files describing your scenarios.
      
      [ FAIL 1 | WARN 0 | SKIP 0 | PASS 0 ]

# test / error handling / should show clean trace when a step throws an error

    Code
      test(tests_path, reporter = testthat::ProgressReporter$new(show_praise = FALSE),
      stop_on_failure = FALSE, ...)
    Output
      v | F W  S  OK | Context
      
      x | 1        0 | Feature: Addition
      --------------------------------------------------------------------------------
      Error ('test-__cucumber__.R:1:1'): Scenario: Adding two numbers
      <cucumber_step_error/rlang_error/error/condition>
      Error: Step "I add them" failed
      i Feature: addition.feature
      i Scenario: Adding two numbers
      i Step defined at: setup-steps.R:6
      Caused by error:
      ! Addition service is unavailable
      --------------------------------------------------------------------------------
      
      == Results =====================================================================
      -- Failed tests ----------------------------------------------------------------
      Error ('test-__cucumber__.R:1:1'): Scenario: Adding two numbers
      <cucumber_step_error/rlang_error/error/condition>
      Error: Step "I add them" failed
      i Feature: addition.feature
      i Scenario: Adding two numbers
      i Step defined at: setup-steps.R:6
      Caused by error:
      ! Addition service is unavailable
      
      [ FAIL 1 | WARN 0 | SKIP 0 | PASS 0 ]

# test / error handling / should run after hook, even after error in step

    Code
      test(tests_path, reporter = testthat::ProgressReporter$new(show_praise = FALSE),
      stop_on_failure = FALSE, ...)
    Output
      v | F W  S  OK | Context
      
      x | 1 2      0 | Feature: Hooks
      --------------------------------------------------------------------------------
      Warning ('test-__cucumber__.R:1:1'): Scenario: After hook is executed even when a step throws an error
      Warning in before hook.
      Backtrace:
          x
       1. \-before(.context, pickle$name) at cucumber/R/execute_pickles.R:39:5
      
      Error ('test-__cucumber__.R:1:1'): Scenario: After hook is executed even when a step throws an error
      <cucumber_step_error/rlang_error/error/condition>
      Error: Step "I start the scenario with error" failed
      i Feature: hooks.feature
      i Scenario: After hook is executed even when a step throws an error
      i Step defined at: setup-steps.R:9
      Caused by error:
      ! Unexpected error!
      
      Warning ('test-__cucumber__.R:1:1'): Scenario: After hook is executed even when a step throws an error
      Warning in after hook, even after error in a step.
      Backtrace:
          x
       1. \-after(.context, pickle$name)
      --------------------------------------------------------------------------------
      
      == Results =====================================================================
      -- Failed tests ----------------------------------------------------------------
      Error ('test-__cucumber__.R:1:1'): Scenario: After hook is executed even when a step throws an error
      <cucumber_step_error/rlang_error/error/condition>
      Error: Step "I start the scenario with error" failed
      i Feature: hooks.feature
      i Scenario: After hook is executed even when a step throws an error
      i Step defined at: setup-steps.R:9
      Caused by error:
      ! Unexpected error!
      
      [ FAIL 1 | WARN 2 | SKIP 0 | PASS 0 ]

# test / error handling / should report failure with `testthat::test_dir`

    Code
      test(tests_path, reporter = testthat::ProgressReporter$new(show_praise = FALSE),
      stop_on_failure = FALSE, ...)
    Output
      v | F W  S  OK | Context
      
      x | 2        1 | Feature: Addition
      --------------------------------------------------------------------------------
      Failure ('test-__cucumber__.R:1:1'): Scenario: Adding integer and float
      Expected `context$result` to equal `expected`.
      Differences:
        `actual`: 2.1
      `expected`: 5.0
      
      Step at: setup-steps-addition.R:6
      
      Failure ('test-__cucumber__.R:1:1'): Scenario: Adding float and float
      Expected `context$result` to equal `expected`.
      Differences:
        `actual`: 2.2
      `expected`: 5.0
      
      Step at: setup-steps-addition.R:6
      --------------------------------------------------------------------------------
      
      x | 1        1 | Feature: Guess the word
      --------------------------------------------------------------------------------
      Failure ('test-__cucumber__.R:1:1'): Scenario: Breaker joins a game
      Expected `nchar(context$word)` to equal `n`.
      Differences:
        `actual`: 5
      `expected`: 6
      
      Step at: setup-steps-guess_the_word.R:17
      --------------------------------------------------------------------------------
      
      == Results =====================================================================
      -- Failed tests ----------------------------------------------------------------
      Failure ('test-__cucumber__.R:1:1'): Scenario: Adding integer and float
      Expected `context$result` to equal `expected`.
      Differences:
        `actual`: 2.1
      `expected`: 5.0
      
      Step at: setup-steps-addition.R:6
      
      Failure ('test-__cucumber__.R:1:1'): Scenario: Adding float and float
      Expected `context$result` to equal `expected`.
      Differences:
        `actual`: 2.2
      `expected`: 5.0
      
      Step at: setup-steps-addition.R:6
      
      Failure ('test-__cucumber__.R:1:1'): Scenario: Breaker joins a game
      Expected `nchar(context$word)` to equal `n`.
      Differences:
        `actual`: 5
      `expected`: 6
      
      Step at: setup-steps-guess_the_word.R:17
      
      [ FAIL 3 | WARN 0 | SKIP 0 | PASS 2 ]

# test / error handling / should show a snippet when a step has no definition

    Code
      test(tests_path, reporter = testthat::ProgressReporter$new(show_praise = FALSE),
      stop_on_failure = FALSE, ...)
    Output
      v | F W  S  OK | Context
      
      x | 1        0 | Feature: Addition
      --------------------------------------------------------------------------------
      Error ('test-__cucumber__.R:1:1'): (code run outside of `test_that()`)
      Error in `match_single_step(step, steps, parameters)`: No step found for: "I add them"
      i Add a step definition:
        given("I add them", function(context) {
        pending()
      })
      --------------------------------------------------------------------------------
      
      == Results =====================================================================
      -- Failed tests ----------------------------------------------------------------
      Error ('test-__cucumber__.R:1:1'): (code run outside of `test_that()`)
      Error in `match_single_step(step, steps, parameters)`: No step found for: "I add them"
      i Add a step definition:
        given("I add them", function(context) {
        pending()
      })
      
      [ FAIL 1 | WARN 0 | SKIP 0 | PASS 0 ]

# test / error handling / should show an error when a step has duplicate definitions

    Code
      test(tests_path, reporter = testthat::ProgressReporter$new(show_praise = FALSE),
      stop_on_failure = FALSE, ...)
    Output
      v | F W  S  OK | Context
      
      x | 1        0 | Feature: Addition
      --------------------------------------------------------------------------------
      Error ('test-__cucumber__.R:1:1'): (code run outside of `test_that()`)
      Error in `match_single_step(step, steps, parameters)`: Multiple steps found for: "I add them"
      Check step definitions for duplicates of: "I add them"
      --------------------------------------------------------------------------------
      
      == Results =====================================================================
      -- Failed tests ----------------------------------------------------------------
      Error ('test-__cucumber__.R:1:1'): (code run outside of `test_that()`)
      Error in `match_single_step(step, steps, parameters)`: Multiple steps found for: "I add them"
      Check step definitions for duplicates of: "I add them"
      
      [ FAIL 1 | WARN 0 | SKIP 0 | PASS 0 ]

# test / error handling / should show an error when a feature file is invalid

    Code
      test(tests_path, reporter = testthat::ProgressReporter$new(show_praise = FALSE),
      stop_on_failure = FALSE, ...)
    Output
      v | F W  S  OK | Context
      
      x | 1        0 | __cucumber__
      --------------------------------------------------------------------------------
      Error ('test-__cucumber__.R:1:1'): (code run outside of `test_that()`)
      Error in `validate_indentation(clean_lines)`: All lines must be indented with ^\s{2}
      i Check the `getOption('cucumber.indent')` option if it is set to your feature file indent.
      --------------------------------------------------------------------------------
      
      == Results =====================================================================
      -- Failed tests ----------------------------------------------------------------
      Error ('test-__cucumber__.R:1:1'): (code run outside of `test_that()`)
      Error in `validate_indentation(clean_lines)`: All lines must be indented with ^\s{2}
      i Check the `getOption('cucumber.indent')` option if it is set to your feature file indent.
      
      [ FAIL 1 | WARN 0 | SKIP 0 | PASS 0 ]

