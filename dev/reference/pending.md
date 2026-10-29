# Mark a step as pending

Call `pending()` in a step or a hook that isn't implemented yet. Outside
of a Cucumber run `pending()` skips the test like
[`testthat::skip()`](https://testthat.r-lib.org/reference/skip.html).

## Usage

``` r
pending(message = "TODO")
```

## Arguments

- message:

  A message explaining why the step is pending.

## Behavior

```
```

### Feature: Pending steps

Call `pending()` in a step to mark it as not implemented yet. The step
is reported as pending, and the steps after it are skipped. A pending
scenario fails the run, unless it's run with `strict = FALSE`. Use it to
write the feature files first and implement the steps later. Hooks can
call `pending()` too.

#### Background:

- Given a package

#### Scenario: A pending step fails the scenario

- Given a file named "features/pending.feature" with

  ``` gherkin
  Feature: Pending
    Scenario: Not yet implemented
      Given a step that is pending
  ```

- And a file named "features/setup-steps.R" with

      given("a step that is pending", function(context) {
        pending("not yet implemented")
      })

- When I run

      test("features", stop_on_failure = FALSE)

- Then the errors are

      [failure] Scenario: Not yet implemented
      Step "a step that is pending" is pending: not yet implemented

- And the steps have these results:

  |                              |         |
  |------------------------------|---------|
  | step                         | status  |
  | Given a step that is pending | pending |

#### Scenario: Steps after a pending step are skipped

- Given a file named "features/pending.feature" with

  ``` gherkin
  Feature: Pending
    Scenario: Skips the rest
      Given a step that is pending
      Then this step should not run
  ```

- And a file named "features/setup-steps.R" with

      given("a step that is pending", function(context) {
        pending()
      })
      then("this step should not run", function(context) {
        stop("this step must not execute")
      })

- When I run

      test("features", stop_on_failure = FALSE)

- Then the steps have these results:

  |                               |         |
  |-------------------------------|---------|
  | step                          | status  |
  | Given a step that is pending  | pending |
  | Then this step should not run | skipped |

#### Scenario Outline: A before hook makes the scenario pending with pending(), strict = \<strict\>

A pending scenario fails the run only in strict mode, like a pending
step.

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Sync the basket
      Given an empty basket
  ```

- And a file named "features/setup-steps.R" with

      before(function(context, scenario) pending("the API client isn't written yet"))
      after(function(context, scenario) cat("after:", scenario$name, scenario$status, "\n"))
      given("an empty basket", function(context) stop("this step must not execute"))

- When I run

      test("features", strict = <strict>, stop_on_failure = FALSE)

- Then the scenario "Sync the basket" is \<outcome\> with "\<message\>"

- And the output includes "after: Sync the basket pending"

- And the steps and hooks have these results:

  |                       |         |
  |-----------------------|---------|
  | step                  | status  |
  | Before                | pending |
  | Given an empty basket | skipped |
  | After                 | passed  |

##### Examples:

|  |  |  |
|----|----|----|
| strict | outcome | message |
| TRUE | failed | Hook [`before()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md) is pending: the API client isn't written yet |
| FALSE | skipped | Reason: Hook [`before()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md) is pending: the API client isn't written yet |

Source: `tests/acceptance/pending_steps.feature`

## Examples

``` r
given("I have {int} cucumbers in my basket", function(n, context) {
  pending("not yet implemented")
})
```
