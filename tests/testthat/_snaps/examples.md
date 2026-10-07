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
        2 scenarios (2 passed)
        5 steps (5 passed)
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
        7 scenarios (7 passed)
        15 steps (15 passed)
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
        4 scenarios (4 passed)
        8 steps (8 passed)
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
        2 scenarios (2 passed)
        6 steps (6 passed)
      --------------------------------------------------------------------------------

# test / should run a Scenario with Given, When, Then, And, But keywords

    Code
      test(tests_path, reporter = CucumberProgressReporter$new(), stop_on_failure = FALSE,
      ...)
    Output
      
      Feature: Addition
        Scenario: Addition should work for 3 numbers
          v Given I have 1
          v And I have 2
          v And I have 3
          v When I add them
          v But I do nothing more
          v Then I get 6
          v And it's over
        Scenario: Addition should work for 5 numbers
          v Given I have 1
          v And I have 2
          v And I have 3
          v And I have 4
          v And I have 5
          v When I add them
          v Then I get 15
        Scenario: Addition should work for 10 numbers
          v Given I have 1
          v * I have 1
          v * I have 1
          v * I have 1
          v * I have 1
          v * I have 1
          v * I have 1
          v * I have 1
          v * I have 1
          v * I have 1
          v When I add them
          v Then I get 10
      
      
      --------------------------------------------------------------------------------
      Summary
        3 scenarios (3 passed)
        26 steps (26 passed)
      --------------------------------------------------------------------------------

# test / should run a Scenario with a Table

    Code
      test(tests_path, reporter = CucumberProgressReporter$new(), stop_on_failure = FALSE,
      ...)
    Output
      
      Feature: Column multiplication
        Scenario: Multiplying selected column
          v Given I have a table
            | x | y | z |
            | 1 | 3 | 5 |
            | 2 | 4 | 6 |
          v When I multiply x column by 2
          v Then I should see the following table
            | x | y | z |
            | 2 | 3 | 5 |
            | 4 | 4 | 6 |
      
      
      --------------------------------------------------------------------------------
      Summary
        1 scenario (1 passed)
        3 steps (3 passed)
      --------------------------------------------------------------------------------

# test / should run a Scenario with a docstring

    Code
      test(tests_path, reporter = CucumberProgressReporter$new(), stop_on_failure = FALSE,
      ...)
    Output
      
      Feature: Docstrings
        Scenario: It is possible to pass docstring to a step
          v Given I have a docstring
            """
            My docstring
            
            It has multiple lines
            
            I will remove this one
            """
          v When I remove line that contains 'I will remove this one'
          v And I remove trailing empty lines
          v Then the docstring looks like this
            """
            My docstring
            
            It has multiple lines
            """
      
      
      --------------------------------------------------------------------------------
      Summary
        1 scenario (1 passed)
        4 steps (4 passed)
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
            | x | y | z |
            | 1 | 3 | 5 |
      
      
      --------------------------------------------------------------------------------
      Summary
        2 scenarios (2 passed)
        3 steps (3 passed)
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
        1 scenario (1 passed)
        2 steps (2 passed)
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
          v And I have a number 1e3
          v When I add them
          v Then I get 2e3
      
      
      --------------------------------------------------------------------------------
      Summary
        2 scenarios (2 passed)
        8 steps (8 passed)
      --------------------------------------------------------------------------------

# test / should run a Scenario with snapshot test

    Code
      test(tests_path, reporter = CucumberProgressReporter$new(), stop_on_failure = FALSE,
      ...)
    Output
      
      Feature: Snapshot
        Scenario: Snapshotting code output
          v Given I have a text
            """
            Hello, world!
            """
          v Then the output should be saved in a snapshot
      
      
      --------------------------------------------------------------------------------
      Summary
        1 scenario (1 passed)
        2 steps (2 passed)
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
        2 scenarios (2 passed)
        5 steps (5 passed)
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
        5 scenarios (5 passed)
        11 steps (11 passed)
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
        1 scenario (1 passed)
        3 steps (3 passed)
      --------------------------------------------------------------------------------

# test / should work with Scenario Outline

    Code
      test(tests_path, reporter = CucumberProgressReporter$new(), stop_on_failure = FALSE,
      ...)
    Output
      
      Feature: Eating
        Scenario: eating (1)
          v Given there are 12 cucumbers
          v When I eat 5 cucumbers
          v Then I should have 7 cucumbers
        Scenario: eating (2)
          v Given there are 20 cucumbers
          v When I eat 5 cucumbers
          v Then I should have 15 cucumbers
        Scenario: eating (3)
          v Given there are 12 cucumbers
          v When I eat 5 cucumbers
          v Then I should have 7 cucumbers
        Scenario: eating (4)
          v Given there are 20 cucumbers
          v When I eat 5 cucumbers
          v Then I should have 15 cucumbers
        Scenario: eating (5)
          v Given there are '5.6' cucumbers
          v Then I should have 5.6 cucumbers
        Scenario: eating (6)
          v Given there are "12" cucumbers
          v Then I should have 12 cucumbers
      
      
      --------------------------------------------------------------------------------
      Summary
        6 scenarios (6 passed)
        16 steps (16 passed)
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
        2 scenarios (2 passed)
        5 steps (5 passed)
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
        2 scenarios (2 passed)
        5 steps (5 passed)
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
        2 scenarios (2 passed)
        5 steps (5 passed)
      --------------------------------------------------------------------------------

