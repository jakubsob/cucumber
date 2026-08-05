# Cucumber Reporter Base Class

Base class for cucumber reporters that extends testthat::Reporter. Adds
step-level and feature-level reporting hooks while maintaining full
compatibility with testthat reporters.

## Details

CucumberReporter extends testthat's Reporter class to add: -
Feature-level hooks: \`start_feature()\`, \`end_feature()\` - Step-level
hooks: \`start_step()\`, \`end_step()\`

These additional hooks are called during cucumber test execution to
provide visibility into individual step execution. Standard testthat
reporters will continue to work unchanged, reporting only at the
scenario (test) level.

## Methods

- \`start_feature(feature_name)\`:

  Called before executing a feature's scenarios

- \`end_feature()\`:

  Called after all scenarios in a feature complete

- \`start_step(step)\`:

  Called before executing a step

- \`end_step(step)\`:

  Called after a step completes, with status/error/duration populated

## Super class

[`testthat::Reporter`](https://testthat.r-lib.org/reference/Reporter.html)
-\> `CucumberReporter`

## Public fields

- `current_feature`:

  Current feature name being executed

- `current_pickle`:

  Current pickle (scenario) being executed

## Methods

### Public methods

- [`CucumberReporter$start_feature()`](#method-CucumberReporter-start_feature)

- [`CucumberReporter$end_feature()`](#method-CucumberReporter-end_feature)

- [`CucumberReporter$start_step()`](#method-CucumberReporter-start_step)

- [`CucumberReporter$end_step()`](#method-CucumberReporter-end_step)

- [`CucumberReporter$clone()`](#method-CucumberReporter-clone)

Inherited methods

- [`testthat::Reporter$.start_context()`](https://testthat.r-lib.org/reference/Reporter.html#method-.start_context)
- [`testthat::Reporter$add_result()`](https://testthat.r-lib.org/reference/Reporter.html#method-add_result)
- [`testthat::Reporter$cat_line()`](https://testthat.r-lib.org/reference/Reporter.html#method-cat_line)
- [`testthat::Reporter$cat_tight()`](https://testthat.r-lib.org/reference/Reporter.html#method-cat_tight)
- [`testthat::Reporter$end_context()`](https://testthat.r-lib.org/reference/Reporter.html#method-end_context)
- [`testthat::Reporter$end_context_if_started()`](https://testthat.r-lib.org/reference/Reporter.html#method-end_context_if_started)
- [`testthat::Reporter$end_file()`](https://testthat.r-lib.org/reference/Reporter.html#method-end_file)
- [`testthat::Reporter$end_reporter()`](https://testthat.r-lib.org/reference/Reporter.html#method-end_reporter)
- [`testthat::Reporter$end_test()`](https://testthat.r-lib.org/reference/Reporter.html#method-end_test)
- [`testthat::Reporter$initialize()`](https://testthat.r-lib.org/reference/Reporter.html#method-initialize)
- [`testthat::Reporter$is_full()`](https://testthat.r-lib.org/reference/Reporter.html#method-is_full)
- [`testthat::Reporter$local_user_output()`](https://testthat.r-lib.org/reference/Reporter.html#method-local_user_output)
- [`testthat::Reporter$rule()`](https://testthat.r-lib.org/reference/Reporter.html#method-rule)
- [`testthat::Reporter$start_context()`](https://testthat.r-lib.org/reference/Reporter.html#method-start_context)
- [`testthat::Reporter$start_file()`](https://testthat.r-lib.org/reference/Reporter.html#method-start_file)
- [`testthat::Reporter$start_reporter()`](https://testthat.r-lib.org/reference/Reporter.html#method-start_reporter)
- [`testthat::Reporter$start_test()`](https://testthat.r-lib.org/reference/Reporter.html#method-start_test)
- [`testthat::Reporter$update()`](https://testthat.r-lib.org/reference/Reporter.html#method-update)

------------------------------------------------------------------------

### Method `start_feature()`

Start a feature

#### Usage

    CucumberReporter$start_feature(feature_name)

#### Arguments

- `feature_name`:

  Name of the feature

------------------------------------------------------------------------

### Method `end_feature()`

End the current feature

#### Usage

    CucumberReporter$end_feature()

------------------------------------------------------------------------

### Method `start_step()`

Start a step

#### Usage

    CucumberReporter$start_step(step)

#### Arguments

- `step`:

  Pickle step object

------------------------------------------------------------------------

### Method `end_step()`

End a step (called after execution with status/error/duration populated)

#### Usage

    CucumberReporter$end_step(step)

#### Arguments

- `step`:

  Pickle step object with execution results

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    CucumberReporter$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
