# CucumberPrettyReporter / prints step-by-step progress

    Code
      testthat::with_reporter(testthat::SilentReporter$new(), {
        cucumber:::execute(cucumber:::parse_gherkin(feature), reporter = reporter)
      })
    Output
      
      Feature: Addition
        Scenario: Add two numbers
          v Given I have entered 50 into the calculator
          v And I have entered 70 into the calculator
          v When I press add
          v Then the result should be 120

# CucumberPrettyReporter / shows errors for failing steps

    Code
      testthat::with_reporter(testthat::SilentReporter$new(), {
        cucumber:::execute(cucumber:::parse_gherkin(feature), reporter = reporter)
      })
    Output
      
      Feature: Failing test
        Scenario: This will fail
          v Given I have a value
          v When I make it wrong
          x Then it should fail
            Step "it should fail" failed
            i Scenario: This will fail
            i Step defined at: test-reporter.R:55
            Expected `context$value` to equal 5.
            Differences:
              `actual`: 10.0
            `expected`:  5.0

# CucumberPrettyReporter / prints docstring and data table step arguments

    Code
      testthat::with_reporter(testthat::SilentReporter$new(), {
        cucumber:::execute(cucumber:::parse_gherkin(feature), reporter = reporter)
      })
    Output
      
      Feature: Step arguments
        Scenario: Steps with a docstring and a table
          v Given a message
            """
            line one
            line two
            """
          v And these people
            | name  | age |
            | Alice | 30  |
            | Bob   | 7   |

# CucumberPrettyReporter / truncates long step arguments to max_lines

    Code
      testthat::with_reporter(testthat::SilentReporter$new(), {
        cucumber:::execute(cucumber:::parse_gherkin(feature), reporter = reporter)
      })
    Output
      
      Feature: Step arguments
        Scenario: Long docstring
          v Given a long message
            """
            line one
            line two
            ... and 2 more line(s)
            """

