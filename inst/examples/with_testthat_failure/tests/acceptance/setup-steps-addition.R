when("I add {float} and {float}", function(x, y, context) {
  context$result <- x + y
})

then("the result is {float}", function(expected, context) {
  expect_equal(context$result, expected)
})
