given("^a step$", function(context) {})

given("^a skipped step$", function(context) {
  skip_scenario()
})

given("^a pending step$", function(context) {
  pending()
})

given("^an ambiguous (.*?)$", function(arg1, context) {})

given("^(.*?) ambiguous step$", function(arg1, context) {})

given("^a failing step$", function(context) {
  stop("whoops")
})
