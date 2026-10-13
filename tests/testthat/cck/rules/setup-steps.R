given("the customer has {int} cents", function(int, context) {
  context$money <- int
})

given("there are chocolate bars in stock", function(context) {
  context$stock <- "Mars"
})

given("there are no chocolate bars in stock", function(context) {
  context$stock <- character()
})

when("the customer tries to buy a {int} cent chocolate bar", function(int, context) {
  if (context$money >= int && length(context$stock) > 0) {
    context$chocolate <- context$stock[[1]]
  }
})

then("the sale should not happen", function(context) {
  expect_null(context$chocolate)
})

then("the sale should happen", function(context) {
  expect_false(is.null(context$chocolate))
})
