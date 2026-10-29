#' {cucumber} Options
#'
#' Internally used, package-specific options.
#' They allow overriding the default behavior of the package.
#'
#' @details
#'
#' The following options are available:
#'
#' - `cucumber.path`
#'
#'   Directory with `.feature` files that [test()] runs and [features_rd()] reads when called without `path`.
#'
#'   default: `r format_option_default("cucumber.path")`
#'
#' - `cucumber.language`
#'
#'   Language of the feature files without a `# language:` line, like `"fr"`.
#'
#'   default: `r format_option_default("cucumber.language")`
#'
#' - `cucumber.docstring_as_lines`
#'
#'   If `TRUE`, step definitions get a Doc String as a character vector of lines,
#'   like in cucumber 2.x, instead of one string.
#'
#'   default: `r format_option_default("cucumber.docstring_as_lines")`
#'
#' - `cucumber.reporter_max_docstring_lines`
#'
#'   Max docstring lines [CucumberPrettyReporter] prints per step before
#'   truncating.
#'
#'   default: `r format_option_default("cucumber.reporter_max_docstring_lines")`
#'
#' - `cucumber.reporter_max_table_lines`
#'
#'   Max data table rows [CucumberPrettyReporter] prints per step before
#'   truncating.
#'
#'   default: `r format_option_default("cucumber.reporter_max_table_lines")`
#'
#' - `cucumber.rd_tags`
#'
#'   Tag expression of the scenarios [features_rd()] puts in help pages.
#'
#'   default: `r format_option_default("cucumber.rd_tags")`
#'
#' - `cucumber.rd_section`
#'
#'   Name of the section [features_rd()] puts scenarios in.
#'
#'   default: `r format_option_default("cucumber.rd_section")`
#'
#' See [base::options()] and [base::getOption()] on how to work with options.
#'
#' @eval features_rd(features = "language.feature")
#'
#' @md
#' @name opts
NULL

#' An option's default as inline code, for `?opts`
#' @param name The option's name
#' @keywords internal
#' @noRd
format_option_default <- function(name) {
  paste0("`", deparse(OPTION_DEFAULTS[[name]]), "`")
}
