then("I should have {int} cucumbers", function(n, context) {
  expect_equal(context$remaining, n)
})
