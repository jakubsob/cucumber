# cucumber Options

Internally used, package-specific options. They allow overriding the
default behavior of the package.

## Details

The following options are available:

- `cucumber.indent`

  Regular expression for the indent of the feature files.

  default: `^\\s{2}`

- `cucumber.reporter_max_docstring_lines`

  Max docstring lines
  [CucumberProgressReporter](https://jakubsobolewski.com/cucumber/reference/CucumberProgressReporter.md)
  prints per step before truncating.

  default: `Inf`

- `cucumber.reporter_max_table_lines`

  Max data table rows
  [CucumberProgressReporter](https://jakubsobolewski.com/cucumber/reference/CucumberProgressReporter.md)
  prints per step before truncating.

  default: `Inf`

See [`base::options()`](https://rdrr.io/r/base/options.html) and
[`base::getOption()`](https://rdrr.io/r/base/options.html) on how to
work with options.
