#' Snapshots
#'
#' @description
#' [testthat::expect_snapshot()] works in step definitions and hooks like in a testthat
#' test. Each feature file has a snapshot file of its own in `_snaps`, next to the feature
#' files, and each snapshot is named after its scenario. [test()] and [run()] save to the
#' same snapshot files, so either checks the snapshots of the other.
#'
#' Review and accept changed snapshots with [testthat::snapshot_review()] and
#' [testthat::snapshot_accept()], given the snapshot file's name and the directory of the
#' feature files, like `snapshot_accept("checkout-basket.feature", "tests/acceptance")`.
#'
#' @seealso `vignette("testthat", package = "cucumber")` compares snapshots of cucumber and testthat.
#' @name snapshots
#' @eval features_rd(features = "r-snapshots.feature")
NULL
