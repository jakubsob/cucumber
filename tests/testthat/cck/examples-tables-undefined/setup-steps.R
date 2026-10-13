given("there are {int} cucumbers", function(int, context) {
  context$count <- int
})

when("I eat {int} cucumbers", function(int, context) {
  context$count <- context$count - int
})

then("I should have {int} cucumbers", function(int, context) {
  expect_equal(context$count, int)
})
