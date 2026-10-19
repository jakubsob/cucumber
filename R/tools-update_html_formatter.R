# Updates the official Cucumber HTML report
# (https://github.com/cucumber/html-formatter) in inst/html-formatter, which
# CucumberHtmlReporter fills with the messages of a run. It's internal, call it
# from the package root:
#
#   devtools::load_all()
#   update_html_formatter()           # latest release
#   update_html_formatter("24.2.0")   # a version
#
# It copies the built files of the npm package @cucumber/html-formatter: the
# page template (index.mustache), its compiled React app (main.js, main.css),
# the favicon (icon.url) and the licenses. The app's sources are in the
# html-formatter and react-components repositories. Check that the version of
# @cucumber/messages it depends on is the one CucumberMessagesReporter writes.

HTML_FORMATTER_FILES <- c(
  "dist/main.js",
  "dist/main.css",
  "dist/main.js.LICENSE.txt",
  "dist/src/index.mustache",
  "dist/src/icon.url",
  "LICENSE"
)

#' Update the official Cucumber HTML report
#'
#' See the comment at the top of R/tools-update_html_formatter.R.
#'
#' @param version Version of the npm package `@cucumber/html-formatter`.
#' @param pkg Path to the package source.
#' @keywords internal
#' @noRd
update_html_formatter <- function(version = "latest", pkg = ".") {
  registry <- "https://registry.npmjs.org/@cucumber/html-formatter"
  manifest <- jsonlite::fromJSON(file.path(registry, version))
  tarball <- file.path(tempdir(), basename(manifest$dist$tarball))
  utils::download.file(manifest$dist$tarball, tarball, quiet = TRUE, mode = "wb")
  out <- file.path(tempdir(), "html-formatter")
  unlink(out, recursive = TRUE)
  utils::untar(tarball, exdir = out)

  to <- file.path(pkg, "inst", "html-formatter")
  dir.create(to, recursive = TRUE, showWarnings = FALSE)
  if (!all(file.copy(file.path(out, "package", HTML_FORMATTER_FILES), to, overwrite = TRUE))) {
    stop("Can't copy the files of @cucumber/html-formatter ", manifest$version)
  }
  writeLines(
    c(
      "The official Cucumber HTML report (https://github.com/cucumber/html-formatter),",
      paste0("npm package @cucumber/html-formatter ", manifest$version, ", built for @cucumber/messages ",
             manifest$devDependencies[["@cucumber/messages"]], ","),
      "copied by update_html_formatter() in R/tools-update_html_formatter.R."
    ),
    file.path(to, "README")
  )
  invisible(manifest$version)
}
