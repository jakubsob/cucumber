options(box.path = system.file("examples/box_support", package = "cucumber"))

box::use(
  R/addition[add],
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

then("the result is {float}", function(expected, context) {
  expect_equal(context$result, expected)
})