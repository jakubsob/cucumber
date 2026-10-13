given("a step with a data table a doc string", function(data_table, doc_string, context) {
  expect_equal(names(data_table), "hello")
  expect_equal(c(doc_string), "world")
})

given("a step with a doc string a data table", function(doc_string, data_table, context) {
  expect_equal(c(doc_string), "hello")
  expect_equal(names(data_table), "world")
})
