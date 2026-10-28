# The JSON schema of Cucumber Messages in tests/testthat/messages-schema, see
# R/tools-update_messages_schema.R. It's compiled once, on first use.
messages_schema <- local({
  schema <- NULL
  function() {
    schema <<- schema %||% jsonvalidate::json_schema$new(
      test_path("messages-schema", "Envelope.schema.json"),
      engine = "ajv"
    )
  }
})

# Expect each message, a line of NDJSON, to follow the schema of Cucumber Messages
expect_valid_messages <- function(lines) {
  testthat::skip_if_not_installed("jsonvalidate")
  for (line in lines) {
    valid <- messages_schema()$validate(line, verbose = TRUE)
    errors <- attr(valid, "errors")
    testthat::expect(
      valid,
      paste0(
        "Message doesn't follow the schema:\n", line, "\n",
        paste0(errors$instancePath, ": ", errors$message, collapse = "\n")
      )
    )
  }
  invisible(lines)
}
