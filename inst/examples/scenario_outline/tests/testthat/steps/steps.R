given("there are {int} cucumbers", function(int, context) {
  context$cucumbers <- int
})

when("I eat {int} cucumbers", function(int, context) {
  context$cucumbers <- context$cucumbers - int
})

then("I should have {int} cucumbers", function(int, context) {
  expect_equal(context$cucumbers, int)
})
