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
#'   Directory with `.feature` files that [test()] runs when called without `path`.
#'
#'   default: `"tests/acceptance"`
#'
#' - `cucumber.docstring_as_lines`
#'
#'   If `TRUE`, step definitions get a Doc String as a character vector of lines,
#'   like in cucumber 2.x, instead of one string.
#'
#'   default: `FALSE`
#'
#' - `cucumber.reporter_max_docstring_lines`
#'
#'   Max docstring lines [CucumberPrettyReporter] prints per step before
#'   truncating.
#'
#'   default: `Inf`
#'
#' - `cucumber.reporter_max_table_lines`
#'
#'   Max data table rows [CucumberPrettyReporter] prints per step before
#'   truncating.
#'
#'   default: `Inf`
#'
#' - `cucumber.rd_tags`
#'
#'   Tag expression of the scenarios [features_rd()] puts in help pages.
#'
#'   default: `"@rd"`
#'
#' - `cucumber.rd_section`
#'
#'   Name of the section [features_rd()] puts scenarios in.
#'
#'   default: `"Specification"`
#'
#' See [base::options()] and [base::getOption()] on how to work with options.
#'
#' @md
#' @name opts
NULL
