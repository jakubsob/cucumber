before(function(context, name) {
  context$before <- TRUE
})

when("I start the scenario", function(context) {

})

then("the before hook was run", function(context) {
  expect_true(context$before)
})
