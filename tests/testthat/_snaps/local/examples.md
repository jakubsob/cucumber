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

# test / should run after hook, even after error in step

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
      Error: Step "I start the scenario with error" failed
      i Defined at: setup-steps.R:9
      Caused by error:
      ! Unexpected error!
      Backtrace:
      x
      1. \-cucumber:::execute_single_step(step, .context) at cucumber/R/execute_pickles.R:42:7
      2.   \-base::tryCatch(...) at cucumber/R/execute_pickles.R:56:3
      3.     \-base (local) tryCatchList(expr, classes, parentenv, handlers)
      4.       \-base (local) tryCatchOne(expr, names, parentenv, handlers[[1L]])
      5.         \-value[[3L]](cond)
      Warning ('test-__cucumber__.R:1:1'): Scenario: After hook is executed even when a step throws an error
      Warning in after hook, even after error in a step.
      Backtrace:
      x
      1. \-after(.context, pickle$name)
      --------------------------------------------------------------------------------
      == Results =====================================================================
      -- Failed tests ----------------------------------------------------------------
      Error ('test-__cucumber__.R:1:1'): Scenario: After hook is executed even when a step throws an error
      Error: Step "I start the scenario with error" failed
      i Defined at: setup-steps.R:9
      Caused by error:
      ! Unexpected error!
      Backtrace:
      x
      1. \-cucumber:::execute_single_step(step, .context) at cucumber/R/execute_pickles.R:42:7
      2.   \-base::tryCatch(...) at cucumber/R/execute_pickles.R:56:3
      3.     \-base (local) tryCatchList(expr, classes, parentenv, handlers)
      4.       \-base (local) tryCatchOne(expr, names, parentenv, handlers[[1L]])
      5.         \-value[[3L]](cond)
      [ FAIL 1 | WARN 2 | SKIP 0 | PASS 0 ]

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

# test / should report failure with `testthat::test_dir`

    Code
      test(tests_path, reporter = testthat::ProgressReporter$new(show_praise = FALSE),
      stop_on_failure = FALSE, ...)
    Output
      v | F W  S  OK | Context
      x | 4        1 | Feature: Addition
      --------------------------------------------------------------------------------
      Failure ('test-__cucumber__.R:1:1'): Scenario: Adding integer and float
      Expected `context$result` to equal `expected`.
      Differences:
      `actual`: 2.1
      `expected`: 5.0
      Backtrace:
      x
      1. \-cucumber:::execute_single_step(step, .context) at cucumber/R/execute_pickles.R:42:7
      2.   +-base::tryCatch(...) at cucumber/R/execute_pickles.R:56:3
      3.   | \-base (local) tryCatchList(expr, classes, parentenv, handlers)
      4.   |   \-base (local) tryCatchOne(expr, names, parentenv, handlers[[1L]])
      5.   |     \-base (local) doTryCatch(return(expr), name, parentenv, handler)
      6.   +-base::withCallingHandlers(...) at cucumber/R/execute_pickles.R:58:7
      7.   +-rlang::exec(step$matched_fn, !!!step$arguments, context = context) at cucumber/R/execute_pickles.R:58:7
      8.   \-`<step>`(expected = 5L, context = `<env>`)
      9.     \-testthat::expect_equal(context$result, expected) at ./setup-steps-addition.R:7:3
      Error ('test-__cucumber__.R:1:1'): Scenario: Adding integer and float
      Error in `invokeRestart("muffle_expectation")`: no 'restart' 'muffle_expectation' found
      Backtrace:
      x
      1. +-cucumber:::execute_single_step(step, .context) at cucumber/R/execute_pickles.R:42:7
      2. | \-base::tryCatch(...) at cucumber/R/execute_pickles.R:56:3
      3. |   \-base (local) tryCatchList(expr, classes, parentenv, handlers)
      4. |     \-base (local) tryCatchOne(expr, names, parentenv, handlers[[1L]])
      5. |       \-value[[3L]](cond)
      6. |         \-base::stop(e) at cucumber/R/execute_pickles.R:111:7
      7. \-testthat (local) `<fn>`(`<expcttn_>`)
      8.   \-base::invokeRestart("muffle_expectation")
      Failure ('test-__cucumber__.R:1:1'): Scenario: Adding float and float
      Expected `context$result` to equal `expected`.
      Differences:
      `actual`: 2.2
      `expected`: 5.0
      Backtrace:
      x
      1. \-cucumber:::execute_single_step(step, .context) at cucumber/R/execute_pickles.R:42:7
      2.   +-base::tryCatch(...) at cucumber/R/execute_pickles.R:56:3
      3.   | \-base (local) tryCatchList(expr, classes, parentenv, handlers)
      4.   |   \-base (local) tryCatchOne(expr, names, parentenv, handlers[[1L]])
      5.   |     \-base (local) doTryCatch(return(expr), name, parentenv, handler)
      6.   +-base::withCallingHandlers(...) at cucumber/R/execute_pickles.R:58:7
      7.   +-rlang::exec(step$matched_fn, !!!step$arguments, context = context) at cucumber/R/execute_pickles.R:58:7
      8.   \-`<step>`(expected = 5L, context = `<env>`)
      9.     \-testthat::expect_equal(context$result, expected) at ./setup-steps-addition.R:7:3
      Error ('test-__cucumber__.R:1:1'): Scenario: Adding float and float
      Error in `invokeRestart("muffle_expectation")`: no 'restart' 'muffle_expectation' found
      Backtrace:
      x
      1. +-cucumber:::execute_single_step(step, .context) at cucumber/R/execute_pickles.R:42:7
      2. | \-base::tryCatch(...) at cucumber/R/execute_pickles.R:56:3
      3. |   \-base (local) tryCatchList(expr, classes, parentenv, handlers)
      4. |     \-base (local) tryCatchOne(expr, names, parentenv, handlers[[1L]])
      5. |       \-value[[3L]](cond)
      6. |         \-base::stop(e) at cucumber/R/execute_pickles.R:111:7
      7. \-testthat (local) `<fn>`(`<expcttn_>`)
      8.   \-base::invokeRestart("muffle_expectation")
      --------------------------------------------------------------------------------
      x | 2        1 | Feature: Guess the word
      --------------------------------------------------------------------------------
      Failure ('test-__cucumber__.R:1:1'): Scenario: Breaker joins a game
      Expected `nchar(context$word)` to equal `n`.
      Differences:
      `actual`: 5
      `expected`: 6
      Backtrace:
      x
      1. \-cucumber:::execute_single_step(step, .context) at cucumber/R/execute_pickles.R:42:7
      2.   +-base::tryCatch(...) at cucumber/R/execute_pickles.R:56:3
      3.   | \-base (local) tryCatchList(expr, classes, parentenv, handlers)
      4.   |   \-base (local) tryCatchOne(expr, names, parentenv, handlers[[1L]])
      5.   |     \-base (local) doTryCatch(return(expr), name, parentenv, handler)
      6.   +-base::withCallingHandlers(...) at cucumber/R/execute_pickles.R:58:7
      7.   +-rlang::exec(step$matched_fn, !!!step$arguments, context = context) at cucumber/R/execute_pickles.R:58:7
      8.   \-`<step>`(n = 6L, context = `<env>`)
      9.     \-testthat::expect_equal(nchar(context$word), n) at ./setup-steps-guess_the_word.R:18:3
      Error ('test-__cucumber__.R:1:1'): Scenario: Breaker joins a game
      Error in `invokeRestart("muffle_expectation")`: no 'restart' 'muffle_expectation' found
      Backtrace:
      x
      1. +-cucumber:::execute_single_step(step, .context) at cucumber/R/execute_pickles.R:42:7
      2. | \-base::tryCatch(...) at cucumber/R/execute_pickles.R:56:3
      3. |   \-base (local) tryCatchList(expr, classes, parentenv, handlers)
      4. |     \-base (local) tryCatchOne(expr, names, parentenv, handlers[[1L]])
      5. |       \-value[[3L]](cond)
      6. |         \-base::stop(e) at cucumber/R/execute_pickles.R:111:7
      7. \-testthat (local) `<fn>`(`<expcttn_>`)
      8.   \-base::invokeRestart("muffle_expectation")
      --------------------------------------------------------------------------------
      == Results =====================================================================
      -- Failed tests ----------------------------------------------------------------
      Failure ('test-__cucumber__.R:1:1'): Scenario: Adding integer and float
      Expected `context$result` to equal `expected`.
      Differences:
      `actual`: 2.1
      `expected`: 5.0
      Backtrace:
      x
      1. \-cucumber:::execute_single_step(step, .context) at cucumber/R/execute_pickles.R:42:7
      2.   +-base::tryCatch(...) at cucumber/R/execute_pickles.R:56:3
      3.   | \-base (local) tryCatchList(expr, classes, parentenv, handlers)
      4.   |   \-base (local) tryCatchOne(expr, names, parentenv, handlers[[1L]])
      5.   |     \-base (local) doTryCatch(return(expr), name, parentenv, handler)
      6.   +-base::withCallingHandlers(...) at cucumber/R/execute_pickles.R:58:7
      7.   +-rlang::exec(step$matched_fn, !!!step$arguments, context = context) at cucumber/R/execute_pickles.R:58:7
      8.   \-`<step>`(expected = 5L, context = `<env>`)
      9.     \-testthat::expect_equal(context$result, expected) at ./setup-steps-addition.R:7:3
      Error ('test-__cucumber__.R:1:1'): Scenario: Adding integer and float
      Error in `invokeRestart("muffle_expectation")`: no 'restart' 'muffle_expectation' found
      Backtrace:
      x
      1. +-cucumber:::execute_single_step(step, .context) at cucumber/R/execute_pickles.R:42:7
      2. | \-base::tryCatch(...) at cucumber/R/execute_pickles.R:56:3
      3. |   \-base (local) tryCatchList(expr, classes, parentenv, handlers)
      4. |     \-base (local) tryCatchOne(expr, names, parentenv, handlers[[1L]])
      5. |       \-value[[3L]](cond)
      6. |         \-base::stop(e) at cucumber/R/execute_pickles.R:111:7
      7. \-testthat (local) `<fn>`(`<expcttn_>`)
      8.   \-base::invokeRestart("muffle_expectation")
      Failure ('test-__cucumber__.R:1:1'): Scenario: Adding float and float
      Expected `context$result` to equal `expected`.
      Differences:
      `actual`: 2.2
      `expected`: 5.0
      Backtrace:
      x
      1. \-cucumber:::execute_single_step(step, .context) at cucumber/R/execute_pickles.R:42:7
      2.   +-base::tryCatch(...) at cucumber/R/execute_pickles.R:56:3
      3.   | \-base (local) tryCatchList(expr, classes, parentenv, handlers)
      4.   |   \-base (local) tryCatchOne(expr, names, parentenv, handlers[[1L]])
      5.   |     \-base (local) doTryCatch(return(expr), name, parentenv, handler)
      6.   +-base::withCallingHandlers(...) at cucumber/R/execute_pickles.R:58:7
      7.   +-rlang::exec(step$matched_fn, !!!step$arguments, context = context) at cucumber/R/execute_pickles.R:58:7
      8.   \-`<step>`(expected = 5L, context = `<env>`)
      9.     \-testthat::expect_equal(context$result, expected) at ./setup-steps-addition.R:7:3
      Error ('test-__cucumber__.R:1:1'): Scenario: Adding float and float
      Error in `invokeRestart("muffle_expectation")`: no 'restart' 'muffle_expectation' found
      Backtrace:
      x
      1. +-cucumber:::execute_single_step(step, .context) at cucumber/R/execute_pickles.R:42:7
      2. | \-base::tryCatch(...) at cucumber/R/execute_pickles.R:56:3
      3. |   \-base (local) tryCatchList(expr, classes, parentenv, handlers)
      4. |     \-base (local) tryCatchOne(expr, names, parentenv, handlers[[1L]])
      5. |       \-value[[3L]](cond)
      6. |         \-base::stop(e) at cucumber/R/execute_pickles.R:111:7
      7. \-testthat (local) `<fn>`(`<expcttn_>`)
      8.   \-base::invokeRestart("muffle_expectation")
      Failure ('test-__cucumber__.R:1:1'): Scenario: Breaker joins a game
      Expected `nchar(context$word)` to equal `n`.
      Differences:
      `actual`: 5
      `expected`: 6
      Backtrace:
      x
      1. \-cucumber:::execute_single_step(step, .context) at cucumber/R/execute_pickles.R:42:7
      2.   +-base::tryCatch(...) at cucumber/R/execute_pickles.R:56:3
      3.   | \-base (local) tryCatchList(expr, classes, parentenv, handlers)
      4.   |   \-base (local) tryCatchOne(expr, names, parentenv, handlers[[1L]])
      5.   |     \-base (local) doTryCatch(return(expr), name, parentenv, handler)
      6.   +-base::withCallingHandlers(...) at cucumber/R/execute_pickles.R:58:7
      7.   +-rlang::exec(step$matched_fn, !!!step$arguments, context = context) at cucumber/R/execute_pickles.R:58:7
      8.   \-`<step>`(n = 6L, context = `<env>`)
      9.     \-testthat::expect_equal(nchar(context$word), n) at ./setup-steps-guess_the_word.R:18:3
      Error ('test-__cucumber__.R:1:1'): Scenario: Breaker joins a game
      Error in `invokeRestart("muffle_expectation")`: no 'restart' 'muffle_expectation' found
      Backtrace:
      x
      1. +-cucumber:::execute_single_step(step, .context) at cucumber/R/execute_pickles.R:42:7
      2. | \-base::tryCatch(...) at cucumber/R/execute_pickles.R:56:3
      3. |   \-base (local) tryCatchList(expr, classes, parentenv, handlers)
      4. |     \-base (local) tryCatchOne(expr, names, parentenv, handlers[[1L]])
      5. |       \-value[[3L]](cond)
      6. |         \-base::stop(e) at cucumber/R/execute_pickles.R:111:7
      7. \-testthat (local) `<fn>`(`<expcttn_>`)
      8.   \-base::invokeRestart("muffle_expectation")
      [ FAIL 6 | WARN 0 | SKIP 0 | PASS 2 ]

# test / should show clean error when a step throws

    Code
      test(tests_path, reporter = testthat::ProgressReporter$new(show_praise = FALSE),
      stop_on_failure = FALSE, ...)
    Output
      v | F W  S  OK | Context
      x | 1        0 | Feature: Addition
      --------------------------------------------------------------------------------
      Error ('test-__cucumber__.R:1:1'): Scenario: Adding two numbers
      Error: Step "I add them" failed
      i Defined at: setup-steps.R:6
      Caused by error:
      ! Addition service is unavailable
      Backtrace:
      x
      1. \-cucumber:::execute_single_step(step, .context) at cucumber/R/execute_pickles.R:42:7
      2.   \-base::tryCatch(...) at cucumber/R/execute_pickles.R:56:3
      3.     \-base (local) tryCatchList(expr, classes, parentenv, handlers)
      4.       \-base (local) tryCatchOne(expr, names, parentenv, handlers[[1L]])
      5.         \-value[[3L]](cond)
      --------------------------------------------------------------------------------
      == Results =====================================================================
      -- Failed tests ----------------------------------------------------------------
      Error ('test-__cucumber__.R:1:1'): Scenario: Adding two numbers
      Error: Step "I add them" failed
      i Defined at: setup-steps.R:6
      Caused by error:
      ! Addition service is unavailable
      Backtrace:
      x
      1. \-cucumber:::execute_single_step(step, .context) at cucumber/R/execute_pickles.R:42:7
      2.   \-base::tryCatch(...) at cucumber/R/execute_pickles.R:56:3
      3.     \-base (local) tryCatchList(expr, classes, parentenv, handlers)
      4.       \-base (local) tryCatchOne(expr, names, parentenv, handlers[[1L]])
      5.         \-value[[3L]](cond)
      [ FAIL 1 | WARN 0 | SKIP 0 | PASS 0 ]

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

# test / should throw an error if no test files are found

    Code
      test(tests_path, reporter = testthat::ProgressReporter$new(show_praise = FALSE),
      stop_on_failure = FALSE, ...)
    Output
      v | F W  S  OK | Context
      x | 1        0 | __cucumber__
      --------------------------------------------------------------------------------
      Error ('test-__cucumber__.R:1:1'): (code run outside of `test_that()`)
      Error in `cucumber::run(".", filter = "this_feature_doesnt_exist")`: No feature files found
      Backtrace:
      x
      1. \-cucumber::run(".", filter = "this_feature_doesnt_exist") at test-__cucumber__.R:1:1
      2.   \-rlang::abort("No feature files found") at cucumber/R/test.R:42:5
      --------------------------------------------------------------------------------
      == Results =====================================================================
      -- Failed tests ----------------------------------------------------------------
      Error ('test-__cucumber__.R:1:1'): (code run outside of `test_that()`)
      Error in `cucumber::run(".", filter = "this_feature_doesnt_exist")`: No feature files found
      Backtrace:
      x
      1. \-cucumber::run(".", filter = "this_feature_doesnt_exist") at test-__cucumber__.R:1:1
      2.   \-rlang::abort("No feature files found") at cucumber/R/test.R:42:5
      [ FAIL 1 | WARN 0 | SKIP 0 | PASS 0 ]

# test / should throw an error if no steps are defined

    Code
      test(tests_path, reporter = testthat::ProgressReporter$new(show_praise = FALSE),
      stop_on_failure = FALSE, ...)
    Output
      v | F W  S  OK | Context
      x | 1        0 | __cucumber__
      --------------------------------------------------------------------------------
      Error ('test-__cucumber__.R:1:1'): (code run outside of `test_that()`)
      <purrr_error_indexed/rlang_error/error/condition>
      Error in `map(.x, .f, ..., .progress = .progress)`: i In index: 1.
      i With name: add.feature.
      Caused by error in `execute()`:
      ! Assertion on 'steps' failed: Must have length >= 1, but has length 0.
      Backtrace:
      x
      1. +-cucumber::run(".", filter = NULL) at test-__cucumber__.R:1:1
      2. | \-purrr::walk(...) at cucumber/R/test.R:45:3
      3. |   \-purrr::map(.x, .f, ..., .progress = .progress)
      4. |     \-purrr:::map_("list", .x, .f, ..., .progress = .progress)
      5. |       +-purrr:::with_indexed_errors(...)
      6. |       | \-base::withCallingHandlers(...)
      7. |       +-purrr:::call_with_cleanup(...)
      8. |       \-cucumber (local) .f(.x[[i]], ...)
      9. |         \-cucumber:::execute(f, tags = tags) at cucumber/R/test.R:48:10
      10. |           \-checkmate::assert_list(steps, min.len = 1) at cucumber/R/execute.R:12:3
      11. |             \-checkmate::makeAssertion(x, res, .var.name, add)
      12. |               \-checkmate:::mstop(...)
      13. |                 \-base::stop(simpleError(sprintf(msg, ...), call.))
      14. \-purrr (local) `<fn>`(`<smplErrr>`)
      15.   \-cli::cli_abort(...)
      16.     \-rlang::abort(...)
      --------------------------------------------------------------------------------
      == Results =====================================================================
      -- Failed tests ----------------------------------------------------------------
      Error ('test-__cucumber__.R:1:1'): (code run outside of `test_that()`)
      <purrr_error_indexed/rlang_error/error/condition>
      Error in `map(.x, .f, ..., .progress = .progress)`: i In index: 1.
      i With name: add.feature.
      Caused by error in `execute()`:
      ! Assertion on 'steps' failed: Must have length >= 1, but has length 0.
      Backtrace:
      x
      1. +-cucumber::run(".", filter = NULL) at test-__cucumber__.R:1:1
      2. | \-purrr::walk(...) at cucumber/R/test.R:45:3
      3. |   \-purrr::map(.x, .f, ..., .progress = .progress)
      4. |     \-purrr:::map_("list", .x, .f, ..., .progress = .progress)
      5. |       +-purrr:::with_indexed_errors(...)
      6. |       | \-base::withCallingHandlers(...)
      7. |       +-purrr:::call_with_cleanup(...)
      8. |       \-cucumber (local) .f(.x[[i]], ...)
      9. |         \-cucumber:::execute(f, tags = tags) at cucumber/R/test.R:48:10
      10. |           \-checkmate::assert_list(steps, min.len = 1) at cucumber/R/execute.R:12:3
      11. |             \-checkmate::makeAssertion(x, res, .var.name, add)
      12. |               \-checkmate:::mstop(...)
      13. |                 \-base::stop(simpleError(sprintf(msg, ...), call.))
      14. \-purrr (local) `<fn>`(`<smplErrr>`)
      15.   \-cli::cli_abort(...)
      16.     \-rlang::abort(...)
      [ FAIL 1 | WARN 0 | SKIP 0 | PASS 0 ]

# test / should run tests with custom loading of steps and support code

    Code
      .test()
    Output
      v | F W  S  OK | Context
      v |          2 | Feature: Guess the word
      == Results =====================================================================
      [ FAIL 0 | WARN 0 | SKIP 0 | PASS 2 ]

