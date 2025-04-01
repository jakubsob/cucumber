given("I am on the main page", function(context) {
  context$driver <- shinytest2::AppDriver$new(
    app = testthat::test_path("../../")
  )
})

when("I select {string} variable", function(variable, context) {
  value <- list(
    "Cylinders" = "cyl",
    "Transmission" = "am",
    "Gears" = "gear"
  )[[variable]]
  context$driver$set_inputs(variable = value)
})

then("the formula display should show {string}", function(formula, context) {
  expect_equal(context$driver$get_text("#caption"), formula)
  context$driver$stop()
})
