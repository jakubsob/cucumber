box::use(
  R/addition[add],
  cucumber[
    given,
    when,
    then,
  ]
)

when("I add {int} and {int}", function(x, y, context) {
  context$result <- add(x, y)
})

then("the result is {int}", function(expected, context) {
  expect_equal(context$result, expected)
})

when("I add {int} and {float}", function(x, y, context) {
  context$result <- add(x, y)
})

when("I add {float} and {float}", function(x, y, context) {
  context$result <- add(x, y)
})

when("I add {float} and '{string}'", function(x, y, context) {
  context$lazy_result <- \() add(x, y)
})

then("the result is {float}", function(expected, context) {
  expect_equal(context$result, expected)
})

then("the result is an error", function(context) {
  expect_error(context$lazy_result())
})
