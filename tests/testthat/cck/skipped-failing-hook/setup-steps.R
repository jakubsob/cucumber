given("a step that skips", function(context) {
  skip_scenario()
})

after(function(context, scenario) {
  stop("whoops")
})
