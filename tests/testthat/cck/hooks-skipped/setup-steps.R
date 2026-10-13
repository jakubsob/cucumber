before(function(context, scenario) {})

before(function(context, scenario) {
  skip_scenario()
}, tags = "@skip-before")

before(function(context, scenario) {})

given("a normal step", function(context) {})

given("a step that skips", function(context) {
  skip_scenario()
})

after(function(context, scenario) {})

after(function(context, scenario) {
  skip_scenario()
}, tags = "@skip-after")

after(function(context, scenario) {})
