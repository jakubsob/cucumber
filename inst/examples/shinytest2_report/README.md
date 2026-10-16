# Screenshots and logs of a failing shinytest2 scenario

The app in `app.R` fails for 0 months, and the scenario "Asking for at least 1 month" catches it.
`tests/acceptance/setup-hooks.R` attaches a screenshot of the app and its logs to the step that
failed. Run `report.R` from this directory to write `cucumber-report.html`.

The report is published at <https://jakubsob.github.io/cucumber/shinytest2-report.html>. To update
it, run `report.R` and copy `cucumber-report.html` to `pkgdown/assets/shinytest2-report.html`.
