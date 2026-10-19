# Run the scenarios, showing their progress and writing the HTML report.
# shinytest2 skips its apps on CRAN, that is unless NOT_CRAN is "true".
Sys.setenv(NOT_CRAN = "true")

cucumber::test(
  "tests/acceptance",
  reporter = cucumber::CucumberMultiReporter$new(list(
    cucumber::CucumberProgressReporter$new(),
    cucumber::CucumberHtmlReporter$new("cucumber-report.html")
  )),
  stop_on_failure = FALSE
)
