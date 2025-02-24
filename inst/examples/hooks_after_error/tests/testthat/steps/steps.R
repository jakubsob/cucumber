after(function(context, name) {
  switch(name,
    "After hook is executed even when a step throws an error" = fail("And 'after' is executed!")
  )
})

when("I start the scenario with error", function(context) {
  stop("Unexpected error!")
})
