testthat::skip_if_not(covr::in_covr())
cucumber::run(test_path("../acceptance"), reporter = SilentReporter$new())
