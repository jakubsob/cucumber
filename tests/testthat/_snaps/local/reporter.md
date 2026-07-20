# CucumberProgressReporter / prints step-by-step progress / Scenario: Add two numbers

    Code
      suppressMessages({
        cucumber:::execute(feature, reporter = reporter)
      })
    Output
      
      Feature: Addition
          v Given I have entered 50 into the calculator
          v Given I have entered 70 into the calculator
          v When I press add
          x Then the result should be 120
            Expected `context$value` to equal `n`.
            Differences:
              `actual`:  70
            `expected`: 120
            
            Step at: test-reporter.R:21
      

# CucumberProgressReporter / shows errors for failing steps / Scenario: This will fail

    Code
      suppressMessages({
        cucumber:::execute(feature, reporter = reporter)
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
            
            Step at: test-reporter.R:110
      

---

    Code
      suppressMessages({
        cucumber:::execute(feature, reporter = reporter)
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
            
            Step at: test-reporter.R:110
      

---

    Code
      suppressMessages({
        cucumber:::execute(feature, reporter = reporter)
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
            
            Step at: test-reporter.R:110
      

---

    Code
      suppressMessages({
        cucumber:::execute(feature, reporter = reporter)
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
            
            Step at: test-reporter.R:110
      

---

    Code
      suppressMessages({
        cucumber:::execute(feature, reporter = reporter)
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
            
            Step at: test-reporter.R:110
      

---

    Code
      suppressMessages({
        cucumber:::execute(feature, reporter = reporter)
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
            
            Step at: test-reporter.R:110
      

---

    Code
      suppressMessages({
        cucumber:::execute(feature, reporter = reporter)
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
            
            Step at: test-reporter.R:110
      

---

    Code
      suppressMessages({
        cucumber:::execute(feature, reporter = reporter)
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
            
            Step at: test-reporter.R:110
      

---

    Code
      suppressMessages({
        cucumber:::execute(feature, reporter = reporter)
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
            
            Step at: test-reporter.R:110
      

---

    Code
      suppressMessages({
        cucumber:::execute(feature, reporter = reporter)
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
            
            Step at: test-reporter.R:110
      

---

    Code
      suppressMessages({
        cucumber:::execute(feature, reporter = reporter)
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
            
            Step at: test-reporter.R:110
      

