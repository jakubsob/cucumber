# Run the scenarios, writing their messages, then write the HTML report.
# shinytest2 skips its apps on CRAN, that is unless NOT_CRAN is "true".
Sys.setenv(NOT_CRAN = "true")

cucumber::test(
  "tests/acceptance",
  reporter = cucumber::CucumberMultiReporter$new(list(
    cucumber::CucumberProgressReporter$new(),
    cucumber::CucumberMessagesReporter$new("cucumber.ndjson")
  )),
  stop_on_failure = FALSE
)
cucumber::write_html_report("cucumber.ndjson", "cucumber-report.html")
