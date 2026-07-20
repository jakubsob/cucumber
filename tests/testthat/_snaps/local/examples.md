# test / should run one feature

    Code
      test(tests_path, reporter = CucumberProgressReporter$new(), stop_on_failure = FALSE,
      ...)
    Output
      
      Feature: Guess the word
        Scenario: Maker starts a game
          v When the Maker starts a game
          v Then the Maker waits for a Breaker to join
        Scenario: Breaker joins a game
          v Given the Maker has started a game with the word 'silky'
          v When the Breaker joins the Maker's game
          v Then the Breaker must guess a word with 5 characters
      
      
      --------------------------------------------------------------------------------
      Summary
        Total: 5 | Passed: 5 | Failed: 0
      --------------------------------------------------------------------------------

# test / should run multiple features

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
          v Then the result is 2.1
        Scenario: Adding float and float
          v When I add 1.1 and 1.1
          v Then the result is 2.2
        Scenario: Adding float and float with signs
          v When I add +11.1 and +11.1
          v Then the result is +22.2
        Scenario: Adding float and float of opposite signs
          v When I add +11.11 and -11.1
          v Then the result is +0.01
      
      
      Feature: Guess the word
        Scenario: Maker starts a game
          v When the Maker starts a game
          v Then the Maker waits for a Breaker to join
        Scenario: Breaker joins a game
          v Given the Maker has started a game with the word 'silky'
          v When the Breaker joins the Maker's game
          v Then the Breaker must guess a word with 5 characters
      
      
      --------------------------------------------------------------------------------
      Summary
        Total: 15 | Passed: 15 | Failed: 0
      --------------------------------------------------------------------------------

# test / should run with box

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
          v Then the result is 2.1
        Scenario: Adding float and float
          v When I add 1.1 and 1.1
          v Then the result is 2.2
        Scenario: Adding float and string
          v When I add 1.1 and 'one'
          v Then the result is an error
      
      
      --------------------------------------------------------------------------------
      Summary
        Total: 8 | Passed: 8 | Failed: 0
      --------------------------------------------------------------------------------

# test / should run with shinytest2

    Code
      test(tests_path, reporter = CucumberProgressReporter$new(), stop_on_failure = FALSE,
      ...)
    Output
      
      Feature: Formula display
        Scenario: Selecting Transmission as the grouping variable
          v Given I am on the main page
          v When I select 'Transmission' variable
          v Then the formula display should show 'mpg ~ am'
        Scenario: Selecting Gears as the grouping variable
          v Given I am on the main page
          v When I select 'Gears' variable
          v Then the formula display should show 'mpg ~ gear'
      
      
      --------------------------------------------------------------------------------
      Summary
        Total: 6 | Passed: 6 | Failed: 0
      --------------------------------------------------------------------------------

# test / should run a Scenario with Given, When, Then, And, But keywords

    Code
      test(tests_path, reporter = CucumberProgressReporter$new(), stop_on_failure = FALSE,
      ...)
    Output
      
      Feature: Addition
        Scenario: Addition should work for 3 numbers
          v Given I have 1
          v Given I have 2
          v Given I have 3
          v When I add them
          v When I do nothing more
          v Then I get 6
          v Then it's over
        Scenario: Addition should work for 5 numbers
          v Given I have 1
          v Given I have 2
          v Given I have 3
          v Given I have 4
          v Given I have 5
          v When I add them
          v Then I get 15
        Scenario: Addition should work for 10 numbers
          v Given I have 1
          v Given I have 1
          v Given I have 1
          v Given I have 1
          v Given I have 1
          v Given I have 1
          v Given I have 1
          v Given I have 1
          v Given I have 1
          v Given I have 1
          v When I add them
          v Then I get 10
      
      
      --------------------------------------------------------------------------------
      Summary
        Total: 26 | Passed: 26 | Failed: 0
      --------------------------------------------------------------------------------

# test / should run a Scenario with a Table

    Code
      test(tests_path, reporter = CucumberProgressReporter$new(), stop_on_failure = FALSE,
      ...)
    Output
      
      Feature: Column multiplication
        Scenario: Multiplying selected column
          v Given I have a table
          v When I multiply x column by 2
          v Then I should see the following table
      
      
      --------------------------------------------------------------------------------
      Summary
        Total: 3 | Passed: 3 | Failed: 0
      --------------------------------------------------------------------------------

# test / should run a Scenario with a docstring

    Code
      test(tests_path, reporter = CucumberProgressReporter$new(), stop_on_failure = FALSE,
      ...)
    Output
      
      Feature: Docstrings
        Scenario: It is possible to pass docstring to a step
          v Given I have a docstring
          v When I remove line that contains 'I will remove this one'
          v When I remove trailing empty lines
          v Then the docstring looks like this
      
      
      --------------------------------------------------------------------------------
      Summary
        Total: 4 | Passed: 4 | Failed: 0
      --------------------------------------------------------------------------------

# test / should run a Scenario with comments

    Code
      test(tests_path, reporter = CucumberProgressReporter$new(), stop_on_failure = FALSE,
      ...)
    Output
      
      Feature: Guess the word
        Scenario: Maker starts a game
          v When the Maker starts a game
          v Then the Maker waits for a Breaker to join
        Scenario: Scenario with a commented scenario after a table
          v When the Maker starts a game with
      
      
      --------------------------------------------------------------------------------
      Summary
        Total: 3 | Passed: 3 | Failed: 0
      --------------------------------------------------------------------------------

# test / should run before and after hooks

    Code
      test(tests_path, reporter = CucumberProgressReporter$new(), stop_on_failure = FALSE,
      ...)
    Output
      
      Feature: Hooks
        Scenario: Before hook is executed
          Warning: 
            Warning in before hook.
          v When I start the scenario
          v Then the before hook was run
          Warning: 
            Warning in after hook.
      
      
      --------------------------------------------------------------------------------
      Summary
        Total: 2 | Passed: 2 | Failed: 0
      --------------------------------------------------------------------------------

# test / should run a Scenario with custom parameters

    Code
      test(tests_path, reporter = CucumberProgressReporter$new(), stop_on_failure = FALSE,
      ...)
    Output
      
      Feature: Addition
        Scenario: I can't add a color to a number
          v Given I have a color red
          v Given I have a person named 'John Doe'
          v When I add them
          v Then 🤯
        Scenario: I can add two numbers in scientific notation
          v Given I have a number 1e3
          v Given I have a number 1e3
          v When I add them
          v Then I get 2e3
      
      
      --------------------------------------------------------------------------------
      Summary
        Total: 8 | Passed: 8 | Failed: 0
      --------------------------------------------------------------------------------

# test / should run a Scenario with snapshot test

    Code
      test(tests_path, reporter = CucumberProgressReporter$new(), stop_on_failure = FALSE,
      ...)
    Output
      
      Feature: Snapshot
        Scenario: Snapshotting code output
          v Given I have a text
          v Then the output should be saved in a snapshot
      
      
      --------------------------------------------------------------------------------
      Summary
        Total: 2 | Passed: 2 | Failed: 0
      --------------------------------------------------------------------------------

# test / should work with an arbitrary test directory

    Code
      test(tests_path, reporter = CucumberProgressReporter$new(), stop_on_failure = FALSE,
      ...)
    Output
      
      Feature: Guess the word
        Scenario: Maker starts a game
          v When the Maker starts a game
          v Then the Maker waits for a Breaker to join
        Scenario: Breaker joins a game
          v Given the Maker has started a game with the word 'silky'
          v When the Breaker joins the Maker's game
          v Then the Breaker must guess a word with 5 characters
      
      
      --------------------------------------------------------------------------------
      Summary
        Total: 5 | Passed: 5 | Failed: 0
      --------------------------------------------------------------------------------

# test / should report success with `testthat::test_dir`

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
          v Then the result is 2.1
        Scenario: Adding float and float
          v When I add 1.1 and 1.1
          v Then the result is 2.2
      
      
      Feature: Guess the word
        Scenario: Maker starts a game
          v When the Maker starts a game
          v Then the Maker waits for a Breaker to join
        Scenario: Breaker joins a game
          v Given the Maker has started a game with the word 'silky'
          v When the Breaker joins the Maker's game
          v Then the Breaker must guess a word with 5 characters
      
      
      --------------------------------------------------------------------------------
      Summary
        Total: 11 | Passed: 11 | Failed: 0
      --------------------------------------------------------------------------------

# test / should work with loading steps from setup files

    Code
      test(tests_path, reporter = CucumberProgressReporter$new(), stop_on_failure = FALSE,
      ...)
    Output
      
      Feature: Eating cucumbers
        Scenario: eat 5 out of 12
          v Given there are 12 cucumbers
          v When I eat 5 cucumbers
          v Then I should have 7 cucumbers
      
      
      --------------------------------------------------------------------------------
      Summary
        Total: 3 | Passed: 3 | Failed: 0
      --------------------------------------------------------------------------------

# test / should work with Scenario Outline

    Code
      test(tests_path, reporter = CucumberProgressReporter$new(), stop_on_failure = FALSE,
      ...)
    Output
      
      Feature: Eating
        Scenario: eating (Example 1)
          v Given there are 12 cucumbers
          v When I eat 5 cucumbers
          v Then I should have 7 cucumbers
        Scenario: eating (Example 2)
          v Given there are 20 cucumbers
          v When I eat 5 cucumbers
          v Then I should have 15 cucumbers
        Scenario: eating (Example 1)
          v Given there are 12 cucumbers
          v When I eat 5 cucumbers
          v Then I should have 7 cucumbers
        Scenario: eating (Example 2)
          v Given there are 20 cucumbers
          v When I eat 5 cucumbers
          v Then I should have 15 cucumbers
        Scenario: eating (Example 1)
          v Given there are '5.6' cucumbers
          v Then I should have 5.6 cucumbers
        Scenario: eating (Example 2)
          v Given there are "12" cucumbers
          v Then I should have 12 cucumbers
      
      
      --------------------------------------------------------------------------------
      Summary
        Total: 16 | Passed: 16 | Failed: 0
      --------------------------------------------------------------------------------

# test / shouldn't run testthat test files

    Code
      test(tests_path, reporter = CucumberProgressReporter$new(), stop_on_failure = FALSE,
      ...)
    Output
      
      Feature: Guess the word
        Scenario: Maker starts a game
          v When the Maker starts a game
          v Then the Maker waits for a Breaker to join
        Scenario: Breaker joins a game
          v Given the Maker has started a game with the word 'silky'
          v When the Breaker joins the Maker's game
          v Then the Breaker must guess a word with 5 characters
      
      
      --------------------------------------------------------------------------------
      Summary
        Total: 5 | Passed: 5 | Failed: 0
      --------------------------------------------------------------------------------

# test / should work with testthat filtering

    Code
      test(tests_path, reporter = CucumberProgressReporter$new(), stop_on_failure = FALSE,
      ...)
    Output
      
      Feature: Guess the word
        Scenario: Maker starts a game
          v When the Maker starts a game
          v Then the Maker waits for a Breaker to join
        Scenario: Breaker joins a game
          v Given the Maker has started a game with the word 'silky'
          v When the Breaker joins the Maker's game
          v Then the Breaker must guess a word with 5 characters
      
      
      --------------------------------------------------------------------------------
      Summary
        Total: 5 | Passed: 5 | Failed: 0
      --------------------------------------------------------------------------------

# test / should run tests with custom loading of steps and support code

    Code
      .test()
    Output
      
      Feature: Guess the word
        Scenario: Maker starts a game
          v When the Maker starts a game
          v Then the Maker waits for a Breaker to join
        Scenario: Breaker joins a game
          v Given the Maker has started a game with the word 'silky'
          v When the Breaker joins the Maker's game
          v Then the Breaker must guess a word with 5 characters
      
      
      --------------------------------------------------------------------------------
      Summary
        Total: 5 | Passed: 5 | Failed: 0
      --------------------------------------------------------------------------------

