#' A run as the official Cucumber HTML report
#'
#' Writes the messages of a run into the page of the official Cucumber HTML
#' report (<https://github.com/cucumber/html-formatter>), the one cucumber-js
#' writes with `--format html`. The page is one file that works offline: it
#' shows every feature with its results, and can be searched and filtered by
#' status, text and tags.
#'
#' @param messages A run: the path of a Cucumber Messages file, written by
#'   [CucumberMessagesReporter], the reporter itself, or what
#'   [read_messages()] returns.
#' @param output Path of the HTML file to write.
#' @return The path of the report, invisibly.
#'
#' @seealso Steps and hooks attach screenshots and logs to the report, see
#'   [attachments] and `vignette("reporting", package = "cucumber")`.
#' @family reports
#' @examples
#' \dontrun{
#' cucumber::test(reporter = cucumber::CucumberMessagesReporter$new("cucumber.ndjson"))
#' cucumber::write_html_report("cucumber.ndjson", "cucumber-report.html")
#' }
#' @export
write_html_report <- function(messages, output = "cucumber-report.html") {
  formatter <- \(file) {
    paste(readLines(system.file("html-formatter", file, package = "cucumber"), encoding = "UTF-8", warn = FALSE), collapse = "\n")
  }
  values <- list(
    title = "Cucumber",
    icon = formatter("icon.url"),
    css = formatter("main.css"),
    custom_css = "",
    # Like the official formatter: a `<` in a script could end it, so it's
    # escaped, which JavaScript reads back as `<`
    messages = gsub("<", "\\x3C", paste(read_messages(messages)$lines, collapse = ","), fixed = TRUE),
    script = formatter("main.js"),
    custom_script = ""
  )

  page <- formatter("index.mustache")
  placeholders <- gregexpr("\\{\\{\\w+\\}\\}", page)
  regmatches(page, placeholders) <- list(unlist(values[gsub("[{}]", "", regmatches(page, placeholders)[[1]])]))
  writeLines(enc2utf8(page), output, useBytes = TRUE)
  invisible(output)
}
