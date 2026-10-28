# Run the scenario under its own testthat reporter, so the snapshot is
# recorded under this test and not under the scenario's nested test, and a
# scenario that fails on purpose stays out of this test's results
expect_report_snapshot <- function(feature, reporter = CucumberPrettyReporter$new(show_praise = FALSE)) {
  .expect_snapshot({
    testthat::with_reporter(testthat::SilentReporter$new(), {
      cucumber:::execute(cucumber:::parse_gherkin(feature), reporter = reporter)
    })
  })
}

describe("CucumberPrettyReporter", {
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

    expect_report_snapshot(feature)
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

    expect_report_snapshot(feature)
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

    expect_report_snapshot(feature)
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

    reporter <- CucumberPrettyReporter$new(
      show_praise = FALSE,
      reporter_max_docstring_lines = 2
    )

    expect_report_snapshot(feature, reporter)
  })
})

describe("run", {
  it("stops with an error of cucumber itself in a scenario, instead of failing the scenario", {
    local_mocked_bindings(test_step_result = function(result) stop("a bug in cucumber"))
    dir <- withr::local_tempdir()
    writeLines(
      c("Feature: Basket", "  Scenario: Add an item", "    Given an empty basket"),
      fs::path(dir, "basket.feature")
    )
    writeLines('given("an empty basket", function(context) {})', fs::path(dir, "setup-steps.R"))

    expect_error(
      test(dir, reporter = NULL, stop_on_failure = FALSE),
      "a bug in cucumber"
    )
  })
})
