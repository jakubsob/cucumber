# Cucumber Query Reporter

The parent of the reporters that report a run when it ends, from what
`new_query()` indexed of its messages, in `private$query`.

## Super class

[`cucumber::CucumberReporter`](https://jakubsob.github.io/cucumber/dev/reference/CucumberReporter.md)
-\> `CucumberQueryReporter`

## Methods

### Public methods

- [`CucumberQueryReporter$start_run()`](#method-CucumberQueryReporter-start_run)

- [`CucumberQueryReporter$add_message()`](#method-CucumberQueryReporter-add_message)

- [`CucumberQueryReporter$clone()`](#method-CucumberQueryReporter-clone)

Inherited methods

- [`cucumber::CucumberReporter$add_warning()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberReporter.html#method-add_warning)
- [`cucumber::CucumberReporter$end_run()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberReporter.html#method-end_run)
- [`cucumber::CucumberReporter$report()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberReporter.html#method-report)

------------------------------------------------------------------------

### Method `start_run()`

Start following the messages of a run

#### Usage

    CucumberQueryReporter$start_run()

------------------------------------------------------------------------

### Method `add_message()`

Follow a message of the run

#### Usage

    CucumberQueryReporter$add_message(envelope)

#### Arguments

- `envelope`:

  A list with one element, named by the message's type

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    CucumberQueryReporter$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
