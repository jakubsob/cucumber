skip_if_not(covr::in_covr())
skip_on_cran()
# The scenarios check testthat's snapshot hints, which testthat hides under R CMD check's reporter
rlang::local_bindings(in_check_reporter = FALSE, .env = testthat:::the)
cucumber::test("../acceptance")
