given("I have a color {color}", function(color, context) {
  context$color <- color
})

given("I have a person named {string}", function(name, context) {
  context$name <- name
})

when("I add them", function(context) {
  context$sum <- \() context$color + context$name
})

then("🤯", function(context) {
  expect_error(context$sum())
})
