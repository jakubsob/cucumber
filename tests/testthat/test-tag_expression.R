# Test data of the official cucumber/tag-expressions, testdata/evaluations.yml.
# Its variables are tags as written, so they are matched with match_tag_expression().
test_that("Tag expressions evaluate like cucumber/tag-expressions", {
  cases <- list(
    list("", list(character(), TRUE), list("x", TRUE), list("y", TRUE)),
    list("not x", list("x", FALSE), list("y", TRUE)),
    list("x and y", list(c("x", "y"), TRUE), list("x", FALSE), list("y", FALSE)),
    list("x or y", list(character(), FALSE), list(c("x", "y"), TRUE), list("x", TRUE), list("y", TRUE)),
    list("x\\(1\\) or y\\(2\\)", list("x(1)", TRUE), list("y(2)", TRUE)),
    list(
      "x\\\\ or y\\\\\\) or z\\\\",
      list("x\\", TRUE), list("y\\)", TRUE), list("z\\", TRUE),
      list("x", FALSE), list("y)", FALSE), list("z", FALSE)
    ),
    list(
      "\\\\x or y\\\\ or z\\\\",
      list("\\x", TRUE), list("y\\", TRUE), list("z\\", TRUE),
      list("x", FALSE), list("y", FALSE), list("z", FALSE)
    )
  )
  for (case in cases) {
    for (test in case[-1]) {
      expect_identical(match_tag_expression(case[[1]], test[[1]]), test[[2]], info = case[[1]])
    }
  }
})

# Test data of the official cucumber/tag-expressions, testdata/errors.yml
test_that("Invalid tag expressions fail like cucumber/tag-expressions", {
  cases <- c(
    "@a @b or" = "Expected operator.",
    "@a and (@b not)" = "Expected operator.",
    "@a and (@b @c) or" = "Expected operator.",
    "@a and or" = "Expected operand.",
    "or or" = "Expected operand.",
    "a and or" = "Expected operand.",
    "a b" = "Expected operator.",
    "( a and b ) )" = "Unmatched ).",
    "( ( a and b )" = "Unmatched (.",
    "x or \\y or z" = "Illegal escape before \"y\".",
    "x\\ or y" = "Expected operator.",
    "a and" = "Expected operand.",
    "a or" = "Expected operand.",
    "not" = "Expected operand.",
    "a and not" = "Expected operand."
  )
  for (expression in names(cases)) {
    expect_error(
      match_tag_expression(expression, character()),
      sprintf("Tag expression \"%s\" could not be parsed because of syntax error: %s", expression, cases[[expression]]),
      fixed = TRUE
    )
  }
})

# Test data of the official cucumber/tag-expressions, testdata/parsing.yml,
# checked through the precedence and grouping each formatted expression shows
test_that("Tag expressions group like cucumber/tag-expressions", {
  # ( ( ( not ( a ) or ( b and not ( c ) ) ) or not ( d ) ) or ( e and f ) )
  expression <- "not a or b and not c or not d or e and f"
  expect_true(match_tag_expression(expression, character()))
  expect_false(match_tag_expression(expression, c("a", "c", "d")))
  expect_true(match_tag_expression(expression, c("a", "b", "d")))
  expect_true(match_tag_expression(expression, c("a", "d", "e", "f")))
  # ( x or y ), parentheses split tokens without whitespace
  expect_true(match_tag_expression("x or(y) ", "y"))
  expect_true(match_tag_expression("x\\(1\\) or(y\\(2\\))", "y(2)"))
  # ( x\  or y ), an escaped space is part of the tag
  expect_true(match_tag_expression("x\\  or y", "x "))
  expect_true(match_tag_expression("( a and b\\\\\\\\)", c("a", "b\\\\")))
})
