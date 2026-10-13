define_parameter_type(
  name = "flight",
  regexp = "([A-Z]{3})-([A-Z]{3})",
  transformer = function(from, to) list(from = from, to = to)
)

given("{flight} has been delayed", function(flight, context) {
  expect_equal(flight$from, "LHR")
  expect_equal(flight$to, "CDG")
})
