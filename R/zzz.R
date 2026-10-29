#' Default values of the {cucumber} options, see `?opts`
#' @keywords internal
#' @noRd
OPTION_DEFAULTS <- list(
  cucumber.path = "tests/acceptance",
  cucumber.language = "en",
  cucumber.docstring_as_lines = FALSE,
  cucumber.reporter_max_docstring_lines = Inf,
  cucumber.reporter_max_table_lines = Inf,
  cucumber.rd_tags = "@rd",
  cucumber.rd_section = "Behavior"
)

.onLoad <- function(libname, pkgname) {
  the$registry <- new_registry()
  unset <- !(names(OPTION_DEFAULTS) %in% names(options()))
  options(OPTION_DEFAULTS[unset])
}
