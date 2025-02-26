before(function(context, name) {
  warning("Warning in before hook.")
})

after(function(context, name) {
  warning("Warning in after hook, even after error in a step.")
})

when("I start the scenario with error", function(context) {
  stop("Unexpected error!")
})
