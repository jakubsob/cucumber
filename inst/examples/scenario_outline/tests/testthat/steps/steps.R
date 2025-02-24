given("there are {int} cucumbers", function(x, context) {
  context$cucumbers <- x
})

given("there are {float} cucumbers", function(x, context) {
  context$cucumbers <- x
})

given("there are {string} cucumbers", function(x, context) {
  context$cucumbers <- as.numeric(x)
})

when("I eat {int} cucumbers", function(x, context) {
  context$cucumbers <- context$cucumbers - x
})

then("I should have {int} cucumbers", function(x, context) {
  expect_equal(context$cucumbers, x)
})

then("I should have {float} cucumbers", function(x, context) {
  expect_equal(context$cucumbers, x)
})
