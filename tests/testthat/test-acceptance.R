testthat::skip_if_not(covr::in_covr())
cucumber::test(test_path("../acceptance"), reporter = SilentReporter$new())
