when("the Maker starts a game", function(context) {
  context$game <- "game"
})

when("the Maker starts a game with", function(table, context) {
  context$game <- "game"
  succeed()
})

then("the Maker waits for a Breaker to join", function(context) {
  expect_equal(context$game, "game")
})

given("the Maker has started a game with the word {string}", function(x, context) {
  context$word <- x
})

when("the Breaker joins the Maker's game", function(context) {

})

then("the Breaker must guess a word with {int} characters", function(n, context) {
  expect_equal(nchar(context$word), n)
})
