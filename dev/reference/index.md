# Package index

## Write steps and hooks

Connect the text of a scenario to R code.

- [`given()`](https://jakubsob.github.io/cucumber/dev/reference/step.md)
  [`when()`](https://jakubsob.github.io/cucumber/dev/reference/step.md)
  [`then()`](https://jakubsob.github.io/cucumber/dev/reference/step.md)
  : Define a step
- [`before()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
  [`after()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
  [`before_step()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
  [`after_step()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
  [`before_all()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
  [`after_all()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
  : Hooks
- [`define_parameter_type()`](https://jakubsob.github.io/cucumber/dev/reference/define_parameter_type.md)
  : Define extra parameters to use in Cucumber steps.
- [`pending()`](https://jakubsob.github.io/cucumber/dev/reference/pending.md)
  : Mark a step as pending
- [`skip_scenario()`](https://jakubsob.github.io/cucumber/dev/reference/skip_scenario.md)
  : Skip a scenario
- [`attachments`](https://jakubsob.github.io/cucumber/dev/reference/attachments.md)
  : Attach data, logs and links to the report

## Run features

Run feature files on their own, or inside testthat.

- [`test()`](https://jakubsob.github.io/cucumber/dev/reference/test.md)
  : Run Cucumber tests

- [`run()`](https://jakubsob.github.io/cucumber/dev/reference/run.md) :

  Run Cucumber tests in a `testthat` context

- [`snapshots`](https://jakubsob.github.io/cucumber/dev/reference/snapshots.md)
  : Snapshots

## Console reporters

Show the progress of a run in the console.

- [`CucumberProgressReporter`](https://jakubsob.github.io/cucumber/dev/reference/CucumberProgressReporter.md)
  : Progress Reporter for Cucumber
- [`CucumberProgressBarReporter`](https://jakubsob.github.io/cucumber/dev/reference/CucumberProgressBarReporter.md)
  : Progress Bar Reporter for Cucumber
- [`CucumberDotsReporter`](https://jakubsob.github.io/cucumber/dev/reference/CucumberDotsReporter.md)
  : Dots Reporter for Cucumber
- [`CucumberSummaryReporter`](https://jakubsob.github.io/cucumber/dev/reference/CucumberSummaryReporter.md)
  : Summary Reporter for Cucumber
- [`CucumberPrettyReporter`](https://jakubsob.github.io/cucumber/dev/reference/CucumberPrettyReporter.md)
  : Pretty Reporter for Cucumber

## Report files

Write a report of a run to a file.

- [`CucumberHtmlReporter`](https://jakubsob.github.io/cucumber/dev/reference/CucumberHtmlReporter.md)
  : Cucumber HTML Reporter
- [`CucumberJunitReporter`](https://jakubsob.github.io/cucumber/dev/reference/CucumberJunitReporter.md)
  : Cucumber JUnit Reporter
- [`CucumberMessagesReporter`](https://jakubsob.github.io/cucumber/dev/reference/CucumberMessagesReporter.md)
  : Cucumber Messages Reporter

## Find what to fix

Reports that list what is left to do.

- [`CucumberRerunReporter`](https://jakubsob.github.io/cucumber/dev/reference/CucumberRerunReporter.md)
  : Cucumber Rerun Reporter
- [`CucumberSnippetsReporter`](https://jakubsob.github.io/cucumber/dev/reference/CucumberSnippetsReporter.md)
  : Cucumber Snippets Reporter
- [`CucumberUsageReporter`](https://jakubsob.github.io/cucumber/dev/reference/CucumberUsageReporter.md)
  : Cucumber Usage Reporter

## Combine and extend reporters

Use several reporters in one run, or write your own.

- [`CucumberMultiReporter`](https://jakubsob.github.io/cucumber/dev/reference/CucumberMultiReporter.md)
  : Combine reporters
- [`CucumberReporter`](https://jakubsob.github.io/cucumber/dev/reference/CucumberReporter.md)
  : Cucumber Reporter Base Class
- [`read_messages()`](https://jakubsob.github.io/cucumber/dev/reference/read_messages.md)
  : Read the Cucumber Messages of a run

## Configure and document

Options of a run, and scenarios in help pages.

- [`opts`](https://jakubsob.github.io/cucumber/dev/reference/opts.md) :
  cucumber Options
- [`features_rd()`](https://jakubsob.github.io/cucumber/dev/reference/features_rd.md)
  : Scenarios as documentation
