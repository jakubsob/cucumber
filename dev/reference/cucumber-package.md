# cucumber: Behavior-Driven Development for R

Write executable specifications in a natural language that describes how
your code should behave. Write specifications in feature files using
'Gherkin' language and execute them using functions implemented in R.
Use them as an extension to your 'testthat' tests to provide a high
level description of how your code works.

## Getting started

Write scenarios in `.feature` files in `tests/acceptance`, see
[`vignette("reference-gherkin", package = "cucumber")`](https://jakubsob.github.io/cucumber/dev/articles/reference-gherkin.md).
Define their steps with
[`given()`](https://jakubsob.github.io/cucumber/dev/reference/step.md),
[`when()`](https://jakubsob.github.io/cucumber/dev/reference/step.md)
and
[`then()`](https://jakubsob.github.io/cucumber/dev/reference/step.md),
and hooks with
[`before()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
and
[`after()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md),
in `setup-*.R` files next to them. Run them with
[`test()`](https://jakubsob.github.io/cucumber/dev/reference/test.md),
or with
[`run()`](https://jakubsob.github.io/cucumber/dev/reference/run.md) in a
testthat test file.

## Help pages

- Steps:
  [step](https://jakubsob.github.io/cucumber/dev/reference/step.md),
  [`define_parameter_type()`](https://jakubsob.github.io/cucumber/dev/reference/define_parameter_type.md),
  [`pending()`](https://jakubsob.github.io/cucumber/dev/reference/pending.md),
  [`skip_scenario()`](https://jakubsob.github.io/cucumber/dev/reference/skip_scenario.md).

- Hooks:
  [hook](https://jakubsob.github.io/cucumber/dev/reference/hook.md).

- Running:
  [`test()`](https://jakubsob.github.io/cucumber/dev/reference/test.md),
  [`run()`](https://jakubsob.github.io/cucumber/dev/reference/run.md),
  [snapshots](https://jakubsob.github.io/cucumber/dev/reference/snapshots.md),
  [opts](https://jakubsob.github.io/cucumber/dev/reference/opts.md).

- Reports:
  [CucumberReporter](https://jakubsob.github.io/cucumber/dev/reference/CucumberReporter.md)
  and its subclasses,
  [attachments](https://jakubsob.github.io/cucumber/dev/reference/attachments.md),
  [`read_messages()`](https://jakubsob.github.io/cucumber/dev/reference/read_messages.md).

- Documentation:
  [`features_rd()`](https://jakubsob.github.io/cucumber/dev/reference/features_rd.md).

## Articles

- [`vignette("bdd", package = "cucumber")`](https://jakubsob.github.io/cucumber/dev/articles/bdd.md):
  Behavior-Driven Development with cucumber.

- [`vignette("how-it-works", package = "cucumber")`](https://jakubsob.github.io/cucumber/dev/articles/how-it-works.md):
  how a run finds and runs steps.

- [`vignette("reference-gherkin", package = "cucumber")`](https://jakubsob.github.io/cucumber/dev/articles/reference-gherkin.md):
  how to write feature files.

- [`vignette("testthat", package = "cucumber")`](https://jakubsob.github.io/cucumber/dev/articles/testthat.md):
  cucumber compared to testthat.

- [`vignette("reporting", package = "cucumber")`](https://jakubsob.github.io/cucumber/dev/articles/reporting.md):
  the HTML report and attachments.

- [`vignette("migration-to-3-0-0", package = "cucumber")`](https://jakubsob.github.io/cucumber/dev/articles/migration-to-3-0-0.md):
  what's new in 3.0.0 and how to migrate.

## See also

Useful links:

- <https://github.com/jakubsob/cucumber>

- Report bugs at <https://github.com/jakubsob/cucumber/issues>

## Author

**Maintainer**: Jakub Sobolewski <jakupsob@gmail.com>
