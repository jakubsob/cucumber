before(function(context, scenario) {}, tags = "@passing-hook")

before(function(context, scenario) {
  stop("Exception in conditional hook")
}, tags = "@fail-before")

when("a step passes", function(context) {})

after(function(context, scenario) {
  stop("Exception in conditional hook")
}, tags = "@fail-after")

after(function(context, scenario) {}, tags = "@passing-hook")
