# test / error handling / should throw an error if no steps are defined

    Code
      test(tests_path, reporter = CucumberProgressReporter$new(), stop_on_failure = FALSE,
      ...)
    Output
        Error: 
          Error in `execute(feature, feature_file = feature_path, tags = tags, reporter = reporter)`: No step definitions found.
          i Define steps using `given()`, `when()`, or `then()`.
          i Steps are typically placed in `setup-*.R` files and are loaded automatically by cucumber.
      
      --------------------------------------------------------------------------------
      Summary
        Total: 0 | Passed: 0 | Failed: 0
      --------------------------------------------------------------------------------

# test / error handling / should throw an error if no test files are found

    Code
      test(tests_path, reporter = CucumberProgressReporter$new(), stop_on_failure = FALSE,
      ...)
    Output
        Error: 
          Error in `cucumber::run(".", filter = "this_feature_doesnt_exist", reporter = getOption(".cucumber_reporter"))`: No feature files found.
          i Add `.feature` files describing your scenarios.
      
      --------------------------------------------------------------------------------
      Summary
        Total: 0 | Passed: 0 | Failed: 0
      --------------------------------------------------------------------------------

# test / error handling / should show clean trace when a step throws an error

    Code
      test(tests_path, reporter = CucumberProgressReporter$new(), stop_on_failure = FALSE,
      ...)
    Output
      
      Feature: Addition
        Scenario: Adding two numbers
          v Given I have 1 and 2
          x When I add them
            Step "I add them" failed
            i Feature: addition.feature
            i Scenario: Adding two numbers
            i Step defined at: setup-steps.R:6
            Caused by error:
            ! Addition service is unavailable
      
      
      --------------------------------------------------------------------------------
      Summary
        Total: 2 | Passed: 1 | Failed: 1
      --------------------------------------------------------------------------------
      
      Failures
      
      Feature: Addition
        Scenario: Adding two numbers
          v Given I have 1 and 2
          x When I add them
            Step "I add them" failed
            i Feature: addition.feature
            i Scenario: Adding two numbers
            i Step defined at: setup-steps.R:6
            Caused by error:
            ! Addition service is unavailable

# test / error handling / should run after hook, even after error in step

    Code
      test(tests_path, reporter = CucumberProgressReporter$new(), stop_on_failure = FALSE,
      ...)
    Output
      
      Feature: Hooks
        Scenario: After hook is executed even when a step throws an error
          Warning: 
            Warning in before hook.
          x When I start the scenario with error
            Step "I start the scenario with error" failed
            i Feature: hooks.feature
            i Scenario: After hook is executed even when a step throws an error
            i Step defined at: setup-steps.R:9
            Caused by error:
            ! Unexpected error!
          Warning: 
            Warning in after hook, even after error in a step.
      
      
      --------------------------------------------------------------------------------
      Summary
        Total: 1 | Passed: 0 | Failed: 1
      --------------------------------------------------------------------------------
      
      Failures
      
      Feature: Hooks
        Scenario: After hook is executed even when a step throws an error
          x When I start the scenario with error
            Step "I start the scenario with error" failed
            i Feature: hooks.feature
            i Scenario: After hook is executed even when a step throws an error
            i Step defined at: setup-steps.R:9
            Caused by error:
            ! Unexpected error!

# test / error handling / should report failure with `testthat::test_dir`

    Code
      test(tests_path, reporter = CucumberProgressReporter$new(), stop_on_failure = FALSE,
      ...)
    Output
      
      Feature: Addition
        Scenario: Adding 2 integers
          v When I add 1 and 1
          v Then the result is 2
        Scenario: Adding integer and float
          v When I add 1 and 1.1
          x Then the result is 5
            Expected `context$result` to equal `expected`.
            Differences:
              `actual`: 2.1
            `expected`: 5.0
            
            Step at: setup-steps-addition.R:6
        Scenario: Adding float and float
          v When I add 1.1 and 1.1
          x Then the result is 5
            Expected `context$result` to equal `expected`.
            Differences:
              `actual`: 2.2
            `expected`: 5.0
            
            Step at: setup-steps-addition.R:6
      
      
      Feature: Guess the word
        Scenario: Maker starts a game
          v When the Maker starts a game
          v Then the Maker waits for a Breaker to join
        Scenario: Breaker joins a game
          v Given the Maker has started a game with the word 'silky'
          v When the Breaker joins the Maker's game
          x Then the Breaker must guess a word with 6 characters
            Expected `nchar(context$word)` to equal `n`.
            Differences:
              `actual`: 5
            `expected`: 6
            
            Step at: setup-steps-guess_the_word.R:17
      
      
      --------------------------------------------------------------------------------
      Summary
        Total: 11 | Passed: 8 | Failed: 3
      --------------------------------------------------------------------------------
      
      Failures
      
      Feature: Addition
        Scenario: Adding integer and float
          v When I add 1 and 1.1
          x Then the result is 5
            Expected `context$result` to equal `expected`.
            Differences:
              `actual`: 2.1
            `expected`: 5.0
            
            Step at: setup-steps-addition.R:6
      
      Feature: Addition
        Scenario: Adding float and float
          v When I add 1.1 and 1.1
          x Then the result is 5
            Expected `context$result` to equal `expected`.
            Differences:
              `actual`: 2.2
            `expected`: 5.0
            
            Step at: setup-steps-addition.R:6
      
      Feature: Guess the word
        Scenario: Breaker joins a game
          v Given the Maker has started a game with the word 'silky'
          v When the Breaker joins the Maker's game
          x Then the Breaker must guess a word with 6 characters
            Expected `nchar(context$word)` to equal `n`.
            Differences:
              `actual`: 5
            `expected`: 6
            
            Step at: setup-steps-guess_the_word.R:17

# test / error handling / should show a snippet when a step has no definition

    Code
      test(tests_path, reporter = CucumberProgressReporter$new(), stop_on_failure = FALSE,
      ...)
    Output
        Error: 
          Error in `match_single_step(step, steps, parameters)`: No step found for: "I add them"
          i Add a step definition:
            when("I add them", function(context) {
              pending()
            })
      
      --------------------------------------------------------------------------------
      Summary
        Total: 0 | Passed: 0 | Failed: 0
      --------------------------------------------------------------------------------

# test / error handling / should show an error when a step has duplicate definitions

    Code
      test(tests_path, reporter = CucumberProgressReporter$new(), stop_on_failure = FALSE,
      ...)
    Output
        Error: 
          Error in `match_single_step(step, steps, parameters)`: Multiple steps found for: "I add them"
          Check step definitions for duplicates of: "I add them"
      
      --------------------------------------------------------------------------------
      Summary
        Total: 0 | Passed: 0 | Failed: 0
      --------------------------------------------------------------------------------

# test / error handling / should show an error when a feature file is invalid

    Code
      test(tests_path, reporter = CucumberProgressReporter$new(), stop_on_failure = FALSE,
      ...)
    Output
        Error: 
          Error in `validate_indentation(clean_lines)`: All lines must be indented with ^\s{2}
          i Check the `getOption('cucumber.indent')` option if it is set to your feature file indent.
      
      --------------------------------------------------------------------------------
      Summary
        Total: 0 | Passed: 0 | Failed: 0
      --------------------------------------------------------------------------------

