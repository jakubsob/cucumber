# CucumberProgressReporter / prints step-by-step progress

    Code
      testthat::with_reporter(testthat::SilentReporter$new(), {
        cucumber:::execute(cucumber:::parse_gherkin(feature), reporter = reporter)
      })
    Output
      
      Feature: Addition
          v Given I have entered 50 into the calculator
          v And I have entered 70 into the calculator
          v When I press add
          v Then the result should be 120
      

# CucumberProgressReporter / shows errors for failing steps

    Code
      testthat::with_reporter(testthat::SilentReporter$new(), {
        cucumber:::execute(cucumber:::parse_gherkin(feature), reporter = reporter)
      })
    Output
      
      Feature: Failing test
          v Given I have a value
          v When I make it wrong
          x Then it should fail
            Expected `context$value` to equal 5.
            Differences:
              `actual`: 10.0
            `expected`:  5.0
            
            Step at: test-reporter.R:55
      

# CucumberProgressReporter / prints docstring and data table step arguments

    Code
      testthat::with_reporter(testthat::SilentReporter$new(), {
        cucumber:::execute(cucumber:::parse_gherkin(feature), reporter = reporter)
      })
    Output
      
      Feature: Step arguments
          v Given a message
            """
            line one
            line two
            """
          v And these people
            | name  | age |
            | Alice | 30  |
            | Bob   | 7   |
      

# CucumberProgressReporter / truncates long step arguments to max_lines

    Code
      testthat::with_reporter(testthat::SilentReporter$new(), {
        cucumber:::execute(cucumber:::parse_gherkin(feature), reporter = reporter)
      })
    Output
      
      Feature: Step arguments
          v Given a long message
            """
            line one
            line two
            ... and 2 more line(s)
            """
      

