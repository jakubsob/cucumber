given("I open the loan calculator", function(context) {
  context$app <- shinytest2::AppDriver$new(testthat::test_path("../../"), name = "loan", width = 900, height = 350)
})

when("I borrow {int} over {int} months", function(amount, months, context) {
  context$app$set_inputs(amount = amount, months = months)
})

then("I see {string}", function(text, context) {
  expect_equal(context$app$get_text("#payment"), text)
})
