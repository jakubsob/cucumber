# test / error handling / should throw an error if no steps are defined

    Code
      test(tests_path, reporter = CucumberPrettyReporter$new(), stop_on_failure = FALSE,
      ...)
    Output
      
      Feature: Add
        Scenario: Add
          U Given I have 1
            No step found for: "I have 1"
            i Add a step definition:
              given("I have {int}", function(int, context) {
              # given("I have {float}", function(float, context) {
                pending()
              })
      
      
      Failures:
      
      1) Scenario: Add # add.feature:2
          U Given I have 1
            No step found for: "I have 1"
            i Add a step definition:
              given("I have {int}", function(int, context) {
              # given("I have {float}", function(float, context) {
                pending()
              })
      
      --------------------------------------------------------------------------------
      Summary
        1 scenario (1 undefined)
        1 step (1 undefined)
        <duration> (executing steps: <duration>)
      --------------------------------------------------------------------------------

# test / error handling / should throw an error if no test files are found

    Code
      test(tests_path, reporter = CucumberPrettyReporter$new(), stop_on_failure = FALSE,
      ...)
    Output
        Error: 
          No feature files found.
          i Add `.feature` files describing your scenarios.
      
      --------------------------------------------------------------------------------
      Summary
        0 scenarios
        0 steps
      --------------------------------------------------------------------------------

# test / error handling / should show clean trace when a step throws an error

    Code
      test(tests_path, reporter = CucumberPrettyReporter$new(), stop_on_failure = FALSE,
      ...)
    Output
      
      Feature: Addition
        Scenario: Adding two numbers
          v Given I have 1 and 2
          x When I add them
          Error: 
            Step "I add them" failed
            i Feature: addition.feature
            i Scenario: Adding two numbers
            i Step defined at: setup-steps.R:6
            Caused by error:
            ! Addition service is unavailable
          - Then the result is 3
      
      
      Failures:
      
      1) Scenario: Adding two numbers # addition.feature:2
          v Given I have 1 and 2
          x When I add them
          Error: 
            Step "I add them" failed
            i Feature: addition.feature
            i Scenario: Adding two numbers
            i Step defined at: setup-steps.R:6
            Caused by error:
            ! Addition service is unavailable
          - Then the result is 3
      
      --------------------------------------------------------------------------------
      Summary
        1 scenario (1 failed)
        3 steps (1 failed, 1 skipped, 1 passed)
        <duration> (executing steps: <duration>)
      --------------------------------------------------------------------------------

# test / error handling / should run after hook, even after error in step

    Code
      test(tests_path, reporter = CucumberPrettyReporter$new(), stop_on_failure = FALSE,
      ...)
    Output
      
      Feature: Hooks
        Scenario: After hook is executed even when a step throws an error
          Warning: 
            Warning in before hook.
          x When I start the scenario with error
          Error: 
            Step "I start the scenario with error" failed
            i Feature: hooks.feature
            i Scenario: After hook is executed even when a step throws an error
            i Step defined at: setup-steps.R:9
            Caused by error:
            ! Unexpected error!
          Warning: 
            Warning in after hook, even after error in a step.
      
      
      Failures:
      
      1) Scenario: After hook is executed even when a step throws an error # hooks.feature:2
          x When I start the scenario with error
          Error: 
            Step "I start the scenario with error" failed
            i Feature: hooks.feature
            i Scenario: After hook is executed even when a step throws an error
            i Step defined at: setup-steps.R:9
            Caused by error:
            ! Unexpected error!
      
      --------------------------------------------------------------------------------
      Summary
        1 scenario (1 failed)
        1 step (1 failed)
        <duration> (executing steps: <duration>)
      --------------------------------------------------------------------------------

# test / error handling / should report failure with `testthat::test_dir`

    Code
      test(tests_path, reporter = CucumberPrettyReporter$new(), stop_on_failure = FALSE,
      ...)
    Output
      
      Feature: Addition
        Scenario: Adding 2 integers
          v When I add 1 and 1
          v Then the result is 2
        Scenario: Adding integer and float
          v When I add 1 and 1.1
          x Then the result is 5
          Error: 
            Step "the result is 5" failed
            i Feature: addition.feature
            i Scenario: Adding integer and float
            i Step defined at: setup-steps-addition.R:5
            Expected `context$result` to equal `expected`.
            Differences:
              `actual`: 2.1
            `expected`: 5.0
        Scenario: Adding float and float
          v When I add 1.1 and 1.1
          x Then the result is 5
          Error: 
            Step "the result is 5" failed
            i Feature: addition.feature
            i Scenario: Adding float and float
            i Step defined at: setup-steps-addition.R:5
            Expected `context$result` to equal `expected`.
            Differences:
              `actual`: 2.2
            `expected`: 5.0
      
      
      Feature: Guess the word
        Scenario: Maker starts a game
          v When the Maker starts a game
          v Then the Maker waits for a Breaker to join
        Scenario: Breaker joins a game
          v Given the Maker has started a game with the word 'silky'
          v When the Breaker joins the Maker's game
          x Then the Breaker must guess a word with 6 characters
          Error: 
            Step "the Breaker must guess a word with 6 characters" failed
            i Feature: guess_the_word.feature
            i Scenario: Breaker joins a game
            i Step defined at: setup-steps-guess_the_word.R:17
            Expected `nchar(context$word)` to equal `n`.
            Differences:
              `actual`: 5
            `expected`: 6
      
      
      Failures:
      
      1) Scenario: Adding integer and float # addition.feature:5
          v When I add 1 and 1.1
          x Then the result is 5
          Error: 
            Step "the result is 5" failed
            i Feature: addition.feature
            i Scenario: Adding integer and float
            i Step defined at: setup-steps-addition.R:5
            Expected `context$result` to equal `expected`.
            Differences:
              `actual`: 2.1
            `expected`: 5.0
      
      2) Scenario: Adding float and float # addition.feature:8
          v When I add 1.1 and 1.1
          x Then the result is 5
          Error: 
            Step "the result is 5" failed
            i Feature: addition.feature
            i Scenario: Adding float and float
            i Step defined at: setup-steps-addition.R:5
            Expected `context$result` to equal `expected`.
            Differences:
              `actual`: 2.2
            `expected`: 5.0
      
      3) Scenario: Breaker joins a game # guess_the_word.feature:5
          v Given the Maker has started a game with the word 'silky'
          v When the Breaker joins the Maker's game
          x Then the Breaker must guess a word with 6 characters
          Error: 
            Step "the Breaker must guess a word with 6 characters" failed
            i Feature: guess_the_word.feature
            i Scenario: Breaker joins a game
            i Step defined at: setup-steps-guess_the_word.R:17
            Expected `nchar(context$word)` to equal `n`.
            Differences:
              `actual`: 5
            `expected`: 6
      
      --------------------------------------------------------------------------------
      Summary
        5 scenarios (3 failed, 2 passed)
        11 steps (3 failed, 8 passed)
        <duration> (executing steps: <duration>)
      --------------------------------------------------------------------------------

# test / error handling / should show a snippet when a step has no definition

    Code
      test(tests_path, reporter = CucumberPrettyReporter$new(), stop_on_failure = FALSE,
      ...)
    Output
      
      Feature: Addition
        Scenario: Adding two numbers
          v Given I have 1 and 2
          U When I add them
            No step found for: "I add them"
            i Add a step definition:
              when("I add them", function(context) {
                pending()
              })
          - Then the result is 3
      
      
      Failures:
      
      1) Scenario: Adding two numbers # addition.feature:2
          v Given I have 1 and 2
          U When I add them
            No step found for: "I add them"
            i Add a step definition:
              when("I add them", function(context) {
                pending()
              })
          - Then the result is 3
      
      --------------------------------------------------------------------------------
      Summary
        1 scenario (1 undefined)
        3 steps (1 undefined, 1 skipped, 1 passed)
        <duration> (executing steps: <duration>)
      --------------------------------------------------------------------------------

# test / error handling / should show an error when a step has duplicate definitions

    Code
      test(tests_path, reporter = CucumberPrettyReporter$new(), stop_on_failure = FALSE,
      ...)
    Output
      
      Feature: Addition
        Scenario: Adding two numbers
          v Given I have 1 and 2
          A When I add them
          Error: 
            Multiple step definitions match: "I add them"
            i Make the step match only one of:
            * "I add them" (setup-steps.R:6)
            * "I add them" (setup-steps.R:10)
          - Then the result is 3
      
      
      Failures:
      
      1) Scenario: Adding two numbers # addition.feature:2
          v Given I have 1 and 2
          A When I add them
          Error: 
            Multiple step definitions match: "I add them"
            i Make the step match only one of:
            * "I add them" (setup-steps.R:6)
            * "I add them" (setup-steps.R:10)
          - Then the result is 3
      
      --------------------------------------------------------------------------------
      Summary
        1 scenario (1 ambiguous)
        3 steps (1 ambiguous, 1 skipped, 1 passed)
        <duration> (executing steps: <duration>)
      --------------------------------------------------------------------------------

# test / error handling / should show an error when a feature file is invalid

    Code
      test(tests_path, reporter = CucumberPrettyReporter$new(), stop_on_failure = FALSE,
      ...)
    Output
        Error: 
          Can't parse feature files
          x Parse error in "broken.feature" (1:1): expected: #EOF, #Language, #TagLine, #FeatureLine, #Comment, #Empty, got 'Scenario: Missing Feature keyword'
          x Parse error in "broken.feature" (2:3): expected: #EOF, #Language, #TagLine, #FeatureLine, #Comment, #Empty, got 'Given something happens'
      
      --------------------------------------------------------------------------------
      Summary
        0 scenarios
        0 steps
      --------------------------------------------------------------------------------

