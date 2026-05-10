given("I have {int} and {int}", function(a, b, context) {
  context$a <- a
  context$b <- b
})

when("I add them", function(context) {
  stop("Addition service is unavailable")
})

then("the result is {int}", function(expected, context) {
  expect_equal(context$result, expected)
})
