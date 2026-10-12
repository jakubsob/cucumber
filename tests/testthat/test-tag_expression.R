test_that("Tag expression parser handles simple tag", {
  result <- evaluate_tag_expression("@a", c("a", "b"))
  expect_true(result)

  result <- evaluate_tag_expression("@a", c("b", "c"))
  expect_false(result)
})

test_that("Tag expression parser handles 'a and b'", {
  result <- evaluate_tag_expression("@a and @b", c("a", "b"))
  expect_true(result)

  result <- evaluate_tag_expression("@a and @b", c("a"))
  expect_false(result)

  result <- evaluate_tag_expression("@a and @b", c("b"))
  expect_false(result)
})

test_that("Tag expression parser handles 'a or b'", {
  result <- evaluate_tag_expression("@a or @b", c("a"))
  expect_true(result)

  result <- evaluate_tag_expression("@a or @b", c("b"))
  expect_true(result)

  result <- evaluate_tag_expression("@a or @b", c("a", "b"))
  expect_true(result)

  result <- evaluate_tag_expression("@a or @b", c("c"))
  expect_false(result)
})

test_that("Tag expression parser handles 'not a'", {
  result <- evaluate_tag_expression("not @a", c("b", "c"))
  expect_true(result)

  result <- evaluate_tag_expression("not @a", c("a"))
  expect_false(result)

  result <- evaluate_tag_expression("not @a", c("a", "b"))
  expect_false(result)
})

test_that("Tag expression parser handles '( a and b ) or ( c and d )'", {
  result <- evaluate_tag_expression("(@a and @b) or (@c and @d)", c("a", "b"))
  expect_true(result)

  result <- evaluate_tag_expression("(@a and @b) or (@c and @d)", c("c", "d"))
  expect_true(result)

  result <- evaluate_tag_expression("(@a and @b) or (@c and @d)", c("a", "c"))
  expect_false(result)

  result <- evaluate_tag_expression("(@a and @b) or (@c and @d)", c("a"))
  expect_false(result)
})

test_that("Tag expression parser handles complex expression with precedence", {
  # not a or b and not c or not d or e and f
  # Should be parsed as: ( ( ( not ( a ) or ( b and not ( c ) ) ) or not ( d ) ) or ( e and f ) )
  expr <- "not @a or @b and not @c or not @d or @e and @f"

  # Case 1: has 'a' -> not a is false, but other clauses might be true
  # has 'd' -> not d is false
  # has 'e' and 'f' -> e and f is true
  result <- evaluate_tag_expression(expr, c("a", "d", "e", "f"))
  expect_true(result) # because (e and f) is true

  # Case 2: has 'b' but not 'c' -> (b and not c) is true
  result <- evaluate_tag_expression(expr, c("b"))
  expect_true(result) # because (b and not c) is true

  # Case 3: has 'b' and 'c' -> (b and not c) is false
  # has 'a' -> not a is false
  # has 'd' -> not d is false
  # doesn't have both e and f
  result <- evaluate_tag_expression(expr, c("a", "b", "c", "d"))
  expect_false(result)

  # Case 4: only has 'a', 'd', and 'c' -> all clauses are false
  result <- evaluate_tag_expression(expr, c("a", "c", "d"))
  expect_false(result)

  # Case 5: no tags -> not a is true
  result <- evaluate_tag_expression(expr, c())
  expect_true(result) # because not a is true
})

test_that("Tag expression parser handles tags with special characters", {
  # Tags can contain alphanumeric, underscore, and hyphen
  result <- evaluate_tag_expression("@tag-name", c("tag-name"))
  expect_true(result)

  result <- evaluate_tag_expression("@tag_name", c("tag_name"))
  expect_true(result)

  result <- evaluate_tag_expression("@tag123", c("tag123"))
  expect_true(result)

  # Tags can also contain dots (for issue tracking integration)
  result <- evaluate_tag_expression("@BJ-x98.77", c("BJ-x98.77"))
  expect_true(result)

  result <- evaluate_tag_expression("@BJ-z12.33", c("BJ-z12.33"))
  expect_true(result)

  # Multiple tags with dots in an expression
  result <- evaluate_tag_expression(
    "@BJ-x98.77 and @BJ-z12.33",
    c("BJ-x98.77", "BJ-z12.33")
  )
  expect_true(result)

  result <- evaluate_tag_expression("@BJ-x98.77 or @BJ-z12.33", c("BJ-x98.77"))
  expect_true(result)

  result <- evaluate_tag_expression("@BJ-x98.77 or @BJ-z12.33", c("BJ-z12.33"))
  expect_true(result)

  result <- evaluate_tag_expression("@BJ-x98.77 or @BJ-z12.33", c("other-tag"))
  expect_false(result)
})

test_that("Tag expression parser is case-sensitive for tags", {
  result <- evaluate_tag_expression("@Tag", c("Tag"))
  expect_true(result)

  result <- evaluate_tag_expression("@Tag", c("tag"))
  expect_false(result)
})

test_that("Tag expression operators are lowercase, other spellings are tags", {
  expect_error(evaluate_tag_expression("@a AND @b", c("a", "b")), "Expected operator.", fixed = TRUE)
  expect_false(evaluate_tag_expression("AND", "x"))
})

test_that("Tag expression handles parentheses for precedence", {
  # Without parentheses: @a or @b and @c
  # With AND having higher precedence, this is: @a or (@b and @c)
  result <- evaluate_tag_expression("@a or @b and @c", c("a"))
  expect_true(result) # a is present

  result <- evaluate_tag_expression("@a or @b and @c", c("b"))
  expect_false(result) # b is present but not c

  result <- evaluate_tag_expression("@a or @b and @c", c("b", "c"))
  expect_true(result) # b and c are present

  # With parentheses: (@a or @b) and @c
  # This changes the precedence
  result <- evaluate_tag_expression("(@a or @b) and @c", c("a"))
  expect_false(result) # a is present but not c

  result <- evaluate_tag_expression("(@a or @b) and @c", c("a", "c"))
  expect_true(result) # a and c are present

  result <- evaluate_tag_expression("(@a or @b) and @c", c("b", "c"))
  expect_true(result) # b and c are present
})

test_that("Tag expression handles nested parentheses", {
  expr <- "((@a or @b) and (@c or @d)) or @e"

  result <- evaluate_tag_expression(expr, c("a", "c"))
  expect_true(result)

  result <- evaluate_tag_expression(expr, c("b", "d"))
  expect_true(result)

  result <- evaluate_tag_expression(expr, c("a"))
  expect_false(result) # a is present but neither c nor d

  result <- evaluate_tag_expression(expr, c("e"))
  expect_true(result) # e makes the whole expression true

  result <- evaluate_tag_expression(expr, c())
  expect_false(result)
})

test_that("Tag expression handles multiple NOT operators", {
  expr <- "not @a and not @b"

  result <- evaluate_tag_expression(expr, c())
  expect_true(result) # neither a nor b present

  result <- evaluate_tag_expression(expr, c("c"))
  expect_true(result) # neither a nor b present

  result <- evaluate_tag_expression(expr, c("a"))
  expect_false(result) # a is present

  result <- evaluate_tag_expression(expr, c("b"))
  expect_false(result) # b is present

  result <- evaluate_tag_expression(expr, c("a", "b"))
  expect_false(result) # both present
})

test_that("Tag expression handles NOT with OR", {
  expr <- "not @a or @b"

  result <- evaluate_tag_expression(expr, c())
  expect_true(result) # not a is true

  result <- evaluate_tag_expression(expr, c("b"))
  expect_true(result) # b is present

  result <- evaluate_tag_expression(expr, c("a"))
  expect_false(result) # a is present and b is not

  result <- evaluate_tag_expression(expr, c("a", "b"))
  expect_true(result) # b is present
})

test_that("Tag expression handles NOT with parentheses", {
  expr <- "not (@a and @b)"

  result <- evaluate_tag_expression(expr, c())
  expect_true(result)

  result <- evaluate_tag_expression(expr, c("a"))
  expect_true(result) # not both

  result <- evaluate_tag_expression(expr, c("b"))
  expect_true(result) # not both

  result <- evaluate_tag_expression(expr, c("a", "b"))
  expect_false(result) # both present
})

test_that("NULL or empty tag expression matches all", {
  result <- evaluate_tag_expression(NULL, c("a", "b"))
  expect_true(result)

  result <- evaluate_tag_expression(character(0), c("a", "b"))
  expect_true(result)
})

test_that("Tag expression handles whitespace", {
  result <- evaluate_tag_expression("  @a   and   @b  ", c("a", "b"))
  expect_true(result)

  result <- evaluate_tag_expression("( @a or @b )", c("a"))
  expect_true(result)

  result <- evaluate_tag_expression("@a     or     @b", c("a"))
  expect_true(result)
})

test_that("Tag expression parser errors on invalid syntax", {
  expect_error(evaluate_tag_expression("@a and", c("a")))
  expect_error(evaluate_tag_expression("and @a", c("a")))
  expect_error(evaluate_tag_expression("@a @b", c("a"))) # Missing operator
  expect_error(evaluate_tag_expression("(@a", c("a"))) # Unclosed parenthesis
  expect_error(evaluate_tag_expression("@a)", c("a"))) # Extra closing parenthesis
})

test_that("A tag without its @ doesn't match", {
  expect_true(evaluate_tag_expression("@smoke and @fast", c("smoke", "fast")))
  expect_false(evaluate_tag_expression("smoke", c("smoke")))
})

test_that("Tags can contain anything but whitespace and unescaped parentheses", {
  expect_true(evaluate_tag_expression("@team:payments", "team:payments"))
  expect_true(evaluate_tag_expression("@a/b or @c", "a/b"))
  expect_true(evaluate_tag_expression("@and-more", "and-more"))
  expect_true(evaluate_tag_expression("@wip\\(x\\)", "wip(x)"))
  expect_true(evaluate_tag_expression("@a@b", "a@b"))
})

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

test_that("Empty tag set with NOT expression", {
  result <- evaluate_tag_expression("not @slow", c())
  expect_true(result) # no tags means slow is not present
})

test_that("Complex real-world scenarios", {
  # Smoke tests that are not slow
  expr1 <- "@smoke and not @slow"
  expect_true(evaluate_tag_expression(expr1, c("smoke", "fast")))
  expect_false(evaluate_tag_expression(expr1, c("smoke", "slow")))
  expect_false(evaluate_tag_expression(expr1, c("fast")))

  # GUI or database tests
  expr2 <- "@gui or @database"
  expect_true(evaluate_tag_expression(expr2, c("gui")))
  expect_true(evaluate_tag_expression(expr2, c("database")))
  expect_true(evaluate_tag_expression(expr2, c("gui", "database")))
  expect_false(evaluate_tag_expression(expr2, c("api")))

  # (Smoke or UI) and not slow
  expr3 <- "(@smoke or @ui) and (not @slow)"
  expect_true(evaluate_tag_expression(expr3, c("smoke", "fast")))
  expect_true(evaluate_tag_expression(expr3, c("ui", "fast")))
  expect_false(evaluate_tag_expression(expr3, c("smoke", "slow")))
  expect_false(evaluate_tag_expression(expr3, c("ui", "slow")))
  expect_false(evaluate_tag_expression(expr3, c("api", "fast")))
})
