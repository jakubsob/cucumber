test_that("validate_tag_placement allows tags on Feature", {
  lines <- c(
    "@smoke",
    "Feature: Test",
    "  Scenario: Test scenario",
    "    Given a step"
  )
  expect_silent(validate_feature(lines))
})

test_that("validate_tag_placement allows tags on Scenario", {
  lines <- c(
    "Feature: Test",
    "  @smoke",
    "  Scenario: Test scenario",
    "    Given a step"
  )
  expect_silent(validate_feature(lines))
})

test_that("validate_tag_placement allows tags on Scenario Outline", {
  lines <- c(
    "Feature: Test",
    "  @smoke",
    "  Scenario Outline: Test scenario",
    "    Given a step with <value>",
    "  Examples:",
    "    | value |",
    "    | 1     |"
  )
  expect_silent(validate_feature(lines))
})

test_that("validate_tag_placement allows tags on Examples", {
  lines <- c(
    "Feature: Test",
    "  Scenario Outline: Test scenario",
    "    Given a step with <value>",
    "  @smoke",
    "  Examples:",
    "    | value |",
    "    | 1     |"
  )
  expect_silent(validate_feature(lines))
})

test_that("validate_tag_placement rejects tags on Background", {
  lines <- c(
    "Feature: Test",
    "  @invalid",
    "  Background:",
    "    Given a step"
  )
  expect_error(
    validate_feature(lines),
    "Tags cannot be placed above.*Background"
  )
})

test_that("validate_tag_placement rejects tags on Given", {
  lines <- c(
    "Feature: Test",
    "  Scenario: Test scenario",
    "    @invalid",
    "    Given a step"
  )
  expect_error(
    validate_feature(lines),
    "Tags cannot be placed above.*Given"
  )
})

test_that("validate_tag_placement rejects tags on When", {
  lines <- c(
    "Feature: Test",
    "  Scenario: Test scenario",
    "    @invalid",
    "    When a step"
  )
  expect_error(
    validate_feature(lines),
    "Tags cannot be placed above.*When"
  )
})

test_that("validate_tag_placement rejects tags on Then", {
  lines <- c(
    "Feature: Test",
    "  Scenario: Test scenario",
    "    @invalid",
    "    Then a step"
  )
  expect_error(
    validate_feature(lines),
    "Tags cannot be placed above.*Then"
  )
})

test_that("validate_tag_placement rejects tags on And", {
  lines <- c(
    "Feature: Test",
    "  Scenario: Test scenario",
    "    Given a step",
    "    @invalid",
    "    And another step"
  )
  expect_error(
    validate_feature(lines),
    "Tags cannot be placed above.*And"
  )
})

test_that("validate_tag_placement rejects tags on But", {
  lines <- c(
    "Feature: Test",
    "  Scenario: Test scenario",
    "    Given a step",
    "    @invalid",
    "    But not this"
  )
  expect_error(
    validate_feature(lines),
    "Tags cannot be placed above.*But"
  )
})

test_that("validate_tag_placement allows multiple tags on same element", {
  lines <- c(
    "@smoke @fast @wip",
    "Feature: Test",
    "  Scenario: Test scenario",
    "    Given a step"
  )
  expect_silent(validate_feature(lines))
})

test_that("validate_tag_placement allows tags on multiple lines", {
  lines <- c(
    "@smoke",
    "@fast",
    "Feature: Test",
    "  Scenario: Test scenario",
    "    Given a step"
  )
  expect_silent(validate_feature(lines))
})

test_that("validate_tag_placement ignores comments between tags and keywords", {
  lines <- c(
    "@smoke",
    "# This is a comment",
    "Feature: Test",
    "  Scenario: Test scenario",
    "    Given a step"
  )
  expect_silent(validate_feature(lines))
})

test_that("validate_tag_placement ignores empty lines between tags and keywords", {
  lines <- c(
    "@smoke",
    "",
    "Feature: Test",
    "  Scenario: Test scenario",
    "    Given a step"
  )
  expect_silent(validate_feature(lines))
})
