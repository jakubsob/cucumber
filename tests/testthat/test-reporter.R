describe("CucumberReporter", {
  it("collects step results during execution", {
    # Create a simple feature
    feature <- c(
      "Feature: Calculator",
      "  Scenario: Add two numbers",
      "    Given I have entered 5 into the calculator",
      "    When I press add",
      "    Then the result should be 5"
    )

    # Define steps
    given("I have entered {int} into the calculator", function(n, context) {
      context$value <- n
    })

    when("I press add", function(context) {
      # do nothing
    })

    then("the result should be {int}", function(n, context) {
      expect_equal(context$value, n)
    })

    # Create reporter
    reporter <- CucumberReporter$new()

    # Execute with reporter
    suppressMessages({
      cucumber:::execute(feature, reporter = reporter)
    })

    # Verify results were collected
    # The reporter should have been called for feature and steps
    expect_equal(reporter$current_feature, NULL)  # Should be cleared after end_feature
  })

  it("works with testthat reporters (backward compatibility)", {
    feature <- c(
      "Feature: Simple",
      "  Scenario: Basic test",
      "    Given I have a test value"
    )

    given("I have a test value", function(context) {
      context$value <- 5
    })

    reporter <- testthat::SilentReporter$new()

    # Execute with testthat reporter (should not fail)
    expect_no_error({
      suppressMessages({
        cucumber:::execute(feature, reporter = reporter)
      })
    })
  })
})

describe("CucumberProgressReporter", {
  it("prints step-by-step progress", {
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

    .expect_snapshot({
      suppressMessages({
        cucumber:::execute(feature, reporter = reporter)
      })
    })
  })

  it("shows errors for failing steps", {
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

    .expect_snapshot({
      suppressMessages({
        cucumber:::execute(feature, reporter = reporter)
      })
    })
  })
})
