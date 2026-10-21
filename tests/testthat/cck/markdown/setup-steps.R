given("some TypeScript code:", function(doc_string, context) {
  expect_true(nzchar(doc_string))
})

given("some classic Gherkin:", function(doc_string, context) {
  expect_true(nzchar(doc_string))
})

when("we use a data table and attach something and then {word}", function(word, data_table, context) {
  expect_true(nrow(data_table) > 0)
  context$log(paste0("We are logging some plain text (", word, ")"))
  if (word == "fail") {
    stop("You asked me to fail")
  }
})

then("this might or might not run", function(context) {
  # no-op
})
