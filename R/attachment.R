#' Attach data, logs and links to the report
#'
#' @description
#' The `context` of a step or a hook attaches data to the report, e.g. a
#' screenshot or what the page showed:
#'
#' - `context$attach(data, media_type, file_name)` attaches a string, or a
#'   raw vector, like a file read with [readBin()]. `media_type` is its
#'   [media type](https://www.iana.org/assignments/media-types/media-types.xhtml),
#'   like `"image/png"` or `"application/json"`. It defaults to `"text/plain"`
#'   for a string, and is required for a raw vector. `file_name` is the name
#'   of the file the reports offer to download it as.
#' - `context$log(text)` attaches text to read, like a log line.
#' - `context$link(...)` attaches links, each one a URL.
#'
#' @seealso The [Reports article](https://jakubsob.github.io/cucumber/articles/reporting.html),
#'   `vignette("reporting", package = "cucumber")`, attaches screenshots and logs of a
#'   failing shinytest2 scenario to the HTML report.
#' @name attachments
#' @examples
#' \dontrun{
#' when("I open the basket", function(context) {
#'   context$session$go_to("/basket")
#'   context$log("Opened /basket")
#'   context$link("https://example.com/basket")
#' })
#'
#' after(function(context, scenario) {
#'   if (scenario$status == "failed") {
#'     file <- tempfile(fileext = ".png")
#'     context$session$screenshot(file)
#'     context$attach(readBin(file, "raw", file.size(file)), "image/png", file_name = "screenshot.png")
#'   }
#' })
#' }
#' @eval features_rd(features = "attachments.feature")
NULL

#' The context of a scenario or a test run hook: an environment for the
#' state shared by steps and hooks, with `attach()`, `log()` and `link()`
#' sending an attachment to where it's reported
#'
#' @param send A function that reports an attachment message
#' @param context The environment to make the context
#' @keywords internal
#' @noRd
new_context <- function(send, context = new.env()) {
  # The message is made before it's sent, so its errors are the step's, not the reporter's
  attach_data <- function(data, media_type = NULL, file_name = NULL) {
    message <- attachment_message(data, media_type, file_name)
    send(message)
    invisible()
  }
  context$attach <- attach_data
  context$log <- function(text) attach_data(text, "text/x.cucumber.log+plain")
  context$link <- function(...) attach_data(paste(c(...), collapse = "\n"), "text/uri-list")
  context
}

#' An attachment's body, encoding and media type: a raw
#' vector is base64 encoded, a string is attached as it is
#' @keywords internal
#' @noRd
attachment_message <- function(data, media_type = NULL, file_name = NULL) {
  checkmate::assert_string(media_type, null.ok = TRUE)
  checkmate::assert_string(file_name, null.ok = TRUE)
  if (is.raw(data)) {
    if (is.null(media_type)) {
      abort("A raw vector attachment must have a `media_type`.", call = NULL, trace = empty_trace())
    }
    rlang::check_installed("jsonlite", "to attach a raw vector.")
    body <- gsub("\n", "", jsonlite::base64_enc(data), fixed = TRUE)
    encoding <- "BASE64"
  } else if (rlang::is_string(data)) {
    body <- as.character(data)
    encoding <- "IDENTITY"
  } else {
    abort("An attachment must be a string or a raw vector.", call = NULL, trace = empty_trace())
  }
  drop_null(list(
    body = body,
    contentEncoding = encoding,
    fileName = file_name,
    mediaType = media_type %||% "text/plain",
    timestamp = timestamp()
  ))
}
