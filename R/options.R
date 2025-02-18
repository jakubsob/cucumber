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
#' - `cucumber.interactive`
#'
#'   Logical value indicating whether to ask which feature files to run.
#'
#'   default: `FALSE`
#'
#' See [base::options()] and [base::getOption()] on how to work with options.
#'
#' @md
#' @name opts
NULL
