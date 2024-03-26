given("I have a docstring", function(docstring, context) {
  context$docstring <- docstring
})

when("I remove line that contains {string}", function(line, context) {
  context$docstring <- context$docstring |>
    purrr::discard(\(x) stringr::str_detect(x, line))
})

when("I remove trailing empty lines", function(context) {
  context$docstring |>
    purrr::discard(\(x) stringr::str_detect(x, "^\\s*$"))
})

then("the docstring looks like this", function(docstring, context) {
  expect_equal(context$docstring, docstring)
})
