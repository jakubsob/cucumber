given("I have a color {color}", function(color, context) {
  context$values <- c(context$values, color)
})

given("I have a number {sci_number}", function(number, context) {
  context$values <- c(context$values, number)
})

given("I have a person named {string}", function(name, context) {
  context$name <- name
})

when("I add them", function(context) {
  context$sum <- \() context$values[1] + context$values[2]
})

then("🤯", function(context) {
  expect_error(context$sum())
})

then("I get {sci_number}", function(number, context) {
  expect_equal(context$sum(), number)
})
