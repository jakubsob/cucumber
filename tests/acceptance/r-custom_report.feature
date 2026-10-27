@rd
Feature: Custom report
  `read_messages()` reads the messages a `CucumberMessagesReporter` wrote as tibbles of the run's
  features, scenarios and steps. Write a report of your own from them, like a summary of a CI job.

  Background:
    Given a package
    And a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          When I add 1 item
          Then the basket has 1 item

        Scenario Outline: Add items
          When I add <n> items
          Then the basket has <expected> items

          Examples:
            | n | expected |
            | 2 | 2        |
            | 3 | 4        |
      """
    And a file named "features/setup-steps.R" with
      """
      when("I add {int} item(s)", function(n, context) context$items <- n)
      then("the basket has {int} item(s)", function(n, context) expect_equal(context$items, n))
      """

  Scenario: A summary of the steps that failed, with their errors
    When I run
      """
      write_failures <- function(messages, output) {
        run <- read_messages(messages)
        failed <- run$steps[run$steps$status == "failed", ]
        writeLines(c(
          paste(sum(run$scenarios$status == "failed"), "of", nrow(run$scenarios), "scenarios failed"),
          paste0("- ", failed$scenario, ": ", failed$keyword, " ", failed$text, "\n  ", failed$error)
        ), output)
      }

      test("features", reporter = CucumberMessagesReporter$new("messages.ndjson"), stop_on_failure = FALSE)
      write_failures("messages.ndjson", "failures.md")
      cat(readLines("failures.md"), sep = "\n")
      """
    Then the output includes
      """
      1 of 3 scenarios failed
      - Add items: Then the basket has 4 items
        Step "the basket has 4 items" failed
        i Feature: basket.feature
        i Scenario: Add items
        i Step defined at: setup-steps.R:2
        Expected `context$items` to equal `n`.
      """

  Scenario: Each example of an outline is a scenario, at the line of its row
    When I run
      """
      test("features", reporter = CucumberMessagesReporter$new("messages.ndjson"), stop_on_failure = FALSE)
      run <- read_messages("messages.ndjson")
      cat(paste0(run$scenarios$uri, ":", run$scenarios$line, " ", run$scenarios$name, " ", run$scenarios$status), sep = "\n")
      """
    Then the output includes
      """
      basket.feature:2 Add an item passed
      basket.feature:12 Add items passed
      basket.feature:13 Add items failed
      """

  Scenario: The messages print how many features and scenarios ran, by status
    When I run
      """
      test("features", reporter = CucumberMessagesReporter$new("messages.ndjson"), stop_on_failure = FALSE)
      print(read_messages("messages.ndjson"))
      """
    Then the output includes "<cucumber_messages> 1 feature, 3 scenarios (1 failed, 2 passed)"
