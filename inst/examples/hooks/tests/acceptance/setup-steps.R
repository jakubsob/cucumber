before(function(context, name) {
  warning("Warning in before hook.")
})

after(function(context, name) {
  warning("Warning in after hook.")
})

when("I start the scenario", function(context) {

})

then("the before hook was run", function(context) {
  succeed("Success.")
})
