before(function(context, scenario) {
  context$attach(readBin("cucumber.svg", "raw", file.size("cucumber.svg")), "image/svg+xml")
})

when("a step passes", function(context) {})

after(function(context, scenario) {
  context$attach(readBin("cucumber.svg", "raw", file.size("cucumber.svg")), "image/svg+xml")
})
