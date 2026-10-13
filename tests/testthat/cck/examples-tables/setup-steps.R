given("there are {int} cucumbers", function(int, context) {
  context$count <- int
})

given("there are {int} friends", function(int, context) {
  context$friends <- int
})

when("I eat {int} cucumbers", function(int, context) {
  context$count <- context$count - int
})

then("I should have {int} cucumbers", function(int, context) {
  expect_equal(context$count, int)
})

then("each person can eat {int} cucumbers", function(int, context) {
  share <- context$count %/% (1 + context$friends)
  expect_equal(share, int)
})
