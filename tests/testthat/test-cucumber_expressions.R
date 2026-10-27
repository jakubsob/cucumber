# The official test data of Cucumber Expressions
# (https://github.com/cucumber/cucumber-expressions/tree/main/testdata/cucumber-expression),
# copied by update_cucumber_expressions() in R/tools-update_cucumber_expressions.R.
skip_if_not_installed("jsonlite")

read_cases <- function(kind) {
  jsonlite::read_json(test_path("cucumber-expressions", paste0(kind, ".json")))
}

# R has no types for numbers of any precision, so these parameter types aren't built in
UNSUPPORTED <- c("matches-bigdecimal", "matches-biginteger")

#' The official error, which an R string's escapes may follow, like
#' `In an R string, double each backslash: "\\/".`
expect_official_error <- function(code, exception) {
  message <- cli::ansi_strip(conditionMessage(expect_error(code)))
  expect_true(startsWith(message, exception), info = message)
  expect_match(substring(message, nchar(exception) + 1), "^(\nIn an R string, .*)?$")
}

describe("Cucumber Expressions", {
  for (name in setdiff(names(cases <- read_cases("matching")), UNSUPPORTED)) {
    case <- cases[[name]]
    it(paste("match like the official ones:", name), {
      local_steps()
      if (!is.null(case$exception)) {
        expect_official_error(expression_to_pattern(case$expression), case$exception)
        return()
      }
      pattern <- expression_to_pattern(case$expression)
      if (is.null(case$expected_args)) {
        expect_false(str_detect(case$text, pattern))
        return()
      }
      expect_true(str_detect(case$text, pattern))
      # A group that didn't match is NA, where it's null in JavaScript
      actual <- lapply(pattern_arguments(case$text, pattern), \(arg) if (identical(arg, NA_character_)) NULL else arg)
      expect_equal(actual, case$expected_args, ignore_attr = TRUE)
    })
  }

  for (kind in c("tokenizer", "parser")) {
    for (name in names(cases <- read_cases(kind))) {
      case <- cases[[name]]
      it(paste("fail like the official ones in the", kind, name), {
        local_steps()
        expect_official_error(expression_to_pattern(case$expression), case$exception)
      })
    }
  }
})
