# Run the scenarios, showing their progress and writing the HTML report.
cucumber::test(
  "tests/acceptance",
  reporter = cucumber::CucumberMultiReporter$new(list(
    cucumber::CucumberProgressReporter$new(),
    cucumber::CucumberHtmlReporter$new("cucumber-report.html")
  )),
  stop_on_failure = FALSE
)
