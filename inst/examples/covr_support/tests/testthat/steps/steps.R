given("I have the number {int}", function(number, context) {
  context$numbers <- c(context$numbers, number)
})

when("I compare the numbers", function(context) {
  context$result <- get_bigger(context$numbers[1], context$numbers[2])
})

then("the result should be {int}", function(expected, context) {
  expect_equal(context$result, expected)
})
