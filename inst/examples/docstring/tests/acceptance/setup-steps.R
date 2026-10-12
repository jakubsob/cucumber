given("I have a docstring", function(docstring, context) {
  context$docstring <- strsplit(docstring, "\n")[[1]]
})

when("I remove line that contains {string}", function(line, context) {
  context$docstring <- context$docstring |>
    purrr::discard(\(x) stringr::str_detect(x, line))
})

when("I remove trailing empty lines", function(context) {
  lines <- context$docstring
  while (length(lines) > 0 && lines[length(lines)] == "") {
    lines <- lines[-length(lines)]
  }
  context$docstring <- lines
})

then("the docstring looks like this", function(docstring, context) {
  expect_equal(paste(context$docstring, collapse = "\n"), docstring)
})
