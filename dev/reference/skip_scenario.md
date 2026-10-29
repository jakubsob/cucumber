# Skip a scenario

Call `skip_scenario()` in a step or in a
[`before()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
or
[`after()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
hook to skip the scenario, e.g. when a service it needs isn't available.
Outside of a Cucumber run `skip_scenario()` skips the test like
[`testthat::skip()`](https://testthat.r-lib.org/reference/skip.html).

## Usage

``` r
skip_scenario(message = "Skipped")
```

## Arguments

- message:

  A message explaining why the scenario is skipped.

## Behavior

```
```

### Feature: Skipped steps

Call `skip_scenario()` in a step or a
[`before()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
hook to skip the rest of the scenario, for example when a service it
needs is down. The scenario is reported as skipped with its reason, and
after hooks still run and get `"skipped"` as its status. In an
[`after()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
hook, it skips only that hook, and the scenario is skipped unless it
already failed, or is pending, undefined or ambiguous. In a
[`before_all()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
hook, it skips every scenario of the run. Calling it in a
[`before_step()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md),
[`after_step()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
or
[`after_all()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
hook is an error of the hook.
[`testthat::skip()`](https://testthat.r-lib.org/reference/skip.html)
does the same.

#### Background:

- Given a package

#### Scenario: A step skips the scenario with skip_scenario()

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Sync the basket
      Given an empty basket
      When I sync the basket
      Then the basket is synced
  ```

- And a file named "features/setup-steps.R" with

      after(function(context, scenario) cat("after:", scenario$name, scenario$status, "\n"))
      given("an empty basket", function(context) {})
      when("I sync the basket", function(context) skip_scenario("the API is down"))
      then("the basket is synced", function(context) stop("this step must not execute"))

- When I run

      test("features")

- Then the scenario "Sync the basket" is skipped with "Reason: the API
  is down"

- And the output includes "after: Sync the basket skipped"

- And the steps have these results:

  |                           |         |
  |---------------------------|---------|
  | step                      | status  |
  | Given an empty basket     | passed  |
  | When I sync the basket    | skipped |
  | Then the basket is synced | skipped |

#### Scenario: A before hook skips the scenario with skip_scenario()

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    @api
    Scenario: Sync the basket
      Given an empty basket
      When I sync the basket

    Scenario: Add an item
      Given an empty basket
  ```

- And a file named "features/setup-steps.R" with

      before(function(context, scenario) skip_scenario("the API is down"), tags = "@api")
      before(function(context, scenario) cat("this hook must not run for", scenario$name, "\n"), tags = "@api")
      after(function(context, scenario) cat("after:", scenario$name, scenario$status, "\n"))
      given("an empty basket", function(context) {})
      when("I sync the basket", function(context) stop("this step must not execute"))

- When I run

      test("features")

- Then the scenario "Sync the basket" is skipped with "Reason: the API
  is down"

- And the output includes

      after: Sync the basket skipped
      after: Add an item passed

- And the output doesn't include "this hook must not run"

- And the steps and hooks have these results:

  |                 |                        |         |
  |-----------------|------------------------|---------|
  | scenario        | step                   | status  |
  | Sync the basket | Before                 | skipped |
  | Sync the basket | Before                 | skipped |
  | Sync the basket | Given an empty basket  | skipped |
  | Sync the basket | When I sync the basket | skipped |
  | Sync the basket | After                  | passed  |
  | Add an item     | Given an empty basket  | passed  |
  | Add an item     | After                  | passed  |

#### Scenario: skip_scenario() in an after hook skips the hook, and the after hooks after it still run

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add an item
      Given an empty basket
  ```

- And a file named "features/setup-steps.R" with

      after(function(context, scenario) cat("this hook still runs\n"))
      after(function(context, scenario) skip_scenario("too late"))
      given("an empty basket", function(context) {})

- When I run

      test("features")

- Then the scenario "Add an item" is skipped with "Reason: too late"

- And the output includes "this hook still runs"

Source: `tests/acceptance/skipped_steps.feature`

## Examples

``` r
before(function(context, scenario) {
  if (!nzchar(Sys.getenv("API_KEY"))) {
    skip_scenario("API_KEY is not set")
  }
}, tags = "@api")
```
