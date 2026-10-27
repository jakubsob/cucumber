# read_messages() reads the messages the CCK expects, in tests/testthat/cck
skip_if_not_installed("jsonlite")

cck_messages <- function(sample) {
  read_messages(test_path("cck", sample, paste0(sample, ".ndjson")))
}

test_that("each example of an outline is a scenario, with its row's line and status", {
  # Arrange
  sample <- "examples-tables"

  # Act
  run <- cck_messages(sample)

  # Assert
  expect_equal(run$scenarios$name[1:5], c(rep("Eating cucumbers", 4), "Eating cucumbers with 11 friends"))
  expect_equal(run$scenarios$line, c(19L, 20L, 25L, 26L, 35L, 36L, 37L))
  expect_equal(run$scenarios$status, c("passed", "passed", "failed", "failed", "passed", "passed", "passed"))
})

test_that("a step that didn't pass has its error", {
  # Arrange
  sample <- "examples-tables"

  # Act
  run <- cck_messages(sample)

  # Assert
  failed <- run$steps[run$steps$status == "failed", ]
  expect_equal(failed$keyword, c("Then", "Then"))
  expect_equal(failed$text, c("I should have 0 cucumbers", "I should have 0 cucumbers"))
  expect_equal(failed$error[[1]], "Expected values to be strictly equal:\n\n-8 !== 0\n")
  expect_true(all(is.na(run$steps$error[run$steps$status == "passed"])))
})

test_that("a scenario in a rule has the rule's name", {
  # Arrange
  in_rules <- "rules"
  without_rules <- "minimal"

  # Act
  run <- cck_messages(in_rules)
  run_without_rules <- cck_messages(without_rules)

  # Assert
  expect_equal(run$scenarios$rule, c(
    "A sale cannot happen if the customer does not have enough money",
    "A sale cannot happen if the customer does not have enough money",
    "a sale cannot happen if there is no stock"
  ))
  expect_true(is.na(run_without_rules$scenarios$rule))
})

test_that("hooks are steps named by the hook, in the order they ran", {
  # Arrange
  sample <- "hooks-named"

  # Act
  run <- cck_messages(sample)

  # Assert
  expect_equal(run$steps$keyword, c("Before", "When", "After"))
  expect_equal(run$steps$text, c("A named before hook", "a step passes", "A named after hook"))
})

test_that("it reads the file of the reporter that wrote it", {
  # Arrange
  file <- test_path("cck", "minimal", "minimal.ndjson")
  reporter <- CucumberMessagesReporter$new(file)

  # Act
  run <- read_messages(reporter)

  # Assert
  expect_equal(run$scenarios, read_messages(file)$scenarios)
})

test_that("it prints how many features and scenarios ran, by status", {
  # Arrange
  run <- cck_messages("examples-tables")

  # Act
  output <- capture.output(print(run))

  # Assert
  expect_equal(output, "<cucumber_messages> 1 feature, 7 scenarios (2 failed, 5 passed) ")
})
