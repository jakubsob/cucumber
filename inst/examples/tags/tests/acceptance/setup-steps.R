given("I have {int}", function(n, context) {
  context$numbers <- c(context$numbers, n)
})

when("I add them", function(context) {
  context$result <- sum(context$numbers)
})

then("I get {int}", function(n, context) {
  expect_equal(context$result, n)
})
