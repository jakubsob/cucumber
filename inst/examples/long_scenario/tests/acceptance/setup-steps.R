given("I have {int}", function(int, context) {
  context$numbers <- c(context$numbers, int)
})

when("I add them", function(context) {
  context$result <- sum(context$numbers)
})

when("I do nothing more", function(context) {

})

then("I get {int}", function(int, context) {
  expect_equal(context$result, int)
})

then("it's over", function(context) {

})
