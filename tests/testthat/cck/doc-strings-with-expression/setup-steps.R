given("a {string} with a doc string:", function(string, doc_string, context) {
  expect_equal(string, "Cucumber")
  expect_equal(c(doc_string), "Cucumis sativus")
})
