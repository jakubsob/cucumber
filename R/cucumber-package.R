#' @keywords internal
#' @section Getting started:
#' Write scenarios in `.feature` files in `r format_option_default("cucumber.path")`, see
#' `vignette("reference-gherkin", package = "cucumber")`. Define their steps with [given()],
#' [when()] and [then()], and hooks with [before()] and [after()], in `setup-*.R` files next
#' to them. Run them with [test()], or with [run()] in a testthat test file.
#'
#' @section Help pages:
#' - Steps: [step], [define_parameter_type()], [pending()], [skip_scenario()].
#' - Hooks: [hook].
#' - Running: [test()], [run()], [snapshots], [opts].
#' - Reports: [CucumberReporter] and its subclasses, [attachments], [read_messages()].
#' - Documentation: [features_rd()].
#'
#' @section Articles:
#' - `vignette("bdd", package = "cucumber")`: Behavior-Driven Development with cucumber.
#' - `vignette("how-it-works", package = "cucumber")`: how a run finds and runs steps.
#' - `vignette("reference-gherkin", package = "cucumber")`: how to write feature files.
#' - `vignette("testthat", package = "cucumber")`: cucumber compared to testthat.
#' - `vignette("reporting", package = "cucumber")`: the HTML report and attachments.
#' - `vignette("migration-to-3-0-0", package = "cucumber")`: what's new in 3.0.0 and how to migrate.
#' @md
"_PACKAGE"
