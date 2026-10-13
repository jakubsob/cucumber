given("a {string} with a table", function(string, data_table, context) {
  expect_equal(string, "Cucumber")
  expect_equal(names(data_table), c("Species", "Cucumis sativus"))
})
