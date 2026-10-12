describe("CucumberProgressReporter", {
  it("prints step-by-step progress", {
    local_steps()
    feature <- c(
      "Feature: Addition",
      "  Scenario: Add two numbers",
      "    Given I have entered 50 into the calculator",
      "    And I have entered 70 into the calculator",
      "    When I press add",
      "    Then the result should be 120"
    )

    given("I have entered {int} into the calculator", function(n, context) {
      if (is.null(context$values)) context$values <- c()
      context$values <- c(context$values, n)
    })

    when("I press add", function(context) {
      context$result <- sum(context$values)
    })

    then("the result should be {int}", function(n, context) {
      expect_equal(context$result, n)
    })

    reporter <- CucumberProgressReporter$new(show_praise = FALSE)

    # Run the scenario under its own testthat reporter, so the snapshot is
    # recorded under this test and not under the scenario's nested test
    .expect_snapshot({
      testthat::with_reporter(testthat::SilentReporter$new(), {
        cucumber:::execute(cucumber:::parse_gherkin(feature), reporter = reporter)
      })
    })
  })

  it("shows errors for failing steps", {
    local_steps()
    feature <- c(
      "Feature: Failing test",
      "  Scenario: This will fail",
      "    Given I have a value",
      "    When I make it wrong",
      "    Then it should fail"
    )

    given("I have a value", function(context) {
      context$value <- 5
    })

    when("I make it wrong", function(context) {
      context$value <- 10
    })

    then("it should fail", function(context) {
      expect_equal(context$value, 5)
    })

    reporter <- CucumberProgressReporter$new(show_praise = FALSE)

    # The scenario fails on purpose, keep its failure out of this test's results
    .expect_snapshot({
      testthat::with_reporter(testthat::SilentReporter$new(), {
        cucumber:::execute(cucumber:::parse_gherkin(feature), reporter = reporter)
      })
    })
  })

  it("prints docstring and data table step arguments", {
    local_steps()
    feature <- c(
      "Feature: Step arguments",
      "  Scenario: Steps with a docstring and a table",
      "    Given a message",
      "      ```",
      "      line one",
      "      line two",
      "      ```",
      "    And these people",
      "      | name  | age |",
      "      | Alice | 30  |",
      "      | Bob   | 7   |"
    )

    given("a message", function(message, context) {})
    given("these people", function(people, context) {})

    reporter <- CucumberProgressReporter$new(show_praise = FALSE)

    # Run the scenario under its own testthat reporter, so the snapshot is
    # recorded under this test and not under the scenario's nested test
    .expect_snapshot({
      testthat::with_reporter(testthat::SilentReporter$new(), {
        cucumber:::execute(cucumber:::parse_gherkin(feature), reporter = reporter)
      })
    })
  })

  it("truncates long step arguments to max_lines", {
    local_steps()
    feature <- c(
      "Feature: Step arguments",
      "  Scenario: Long docstring",
      "    Given a long message",
      "      ```",
      "      line one",
      "      line two",
      "      line three",
      "      line four",
      "      ```"
    )

    given("a long message", function(message, context) {})

    reporter <- CucumberProgressReporter$new(
      show_praise = FALSE,
      reporter_max_docstring_lines = 2
    )

    # Run the scenario under its own testthat reporter, so the snapshot is
    # recorded under this test and not under the scenario's nested test
    .expect_snapshot({
      testthat::with_reporter(testthat::SilentReporter$new(), {
        cucumber:::execute(cucumber:::parse_gherkin(feature), reporter = reporter)
      })
    })
  })
})
