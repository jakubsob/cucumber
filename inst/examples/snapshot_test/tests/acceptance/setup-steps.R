given("I have a text", function(text, context) {
  context$text <- text
})

then("the output should be saved in a snapshot", function(context) {
  testthat::expect_snapshot(context$text)
})
