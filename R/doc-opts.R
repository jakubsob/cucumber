#' {cucumber} Options
#'
#' Internally used, package-specific options.
#' They allow overriding the default behavior of the package.
#'
#' @details
#'
#' The following options are available:
#'
#' - `cucumber.indent`
#'
#'   Regular expression for the indent of the feature files.
#'
#'   default: `^\\s{2}`
#'
#' - `cucumber.reporter_max_docstring_lines`
#'
#'   Max docstring lines [CucumberProgressReporter] prints per step before
#'   truncating.
#'
#'   default: `Inf`
#'
#' - `cucumber.reporter_max_table_lines`
#'
#'   Max data table rows [CucumberProgressReporter] prints per step before
#'   truncating.
#'
#'   default: `Inf`
#'
#' See [base::options()] and [base::getOption()] on how to work with options.
#'
#' @md
#' @name opts
NULL
