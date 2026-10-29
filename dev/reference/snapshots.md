# Snapshots

[`testthat::expect_snapshot()`](https://testthat.r-lib.org/reference/expect_snapshot.html)
works in step definitions and hooks like in a testthat test. Each
feature file has a snapshot file of its own in `_snaps`, next to the
feature files, and each snapshot is named after its scenario.
[`test()`](https://jakubsob.github.io/cucumber/dev/reference/test.md)
and [`run()`](https://jakubsob.github.io/cucumber/dev/reference/run.md)
save to the same snapshot files, so either checks the snapshots of the
other.

Review and accept changed snapshots with
[`testthat::snapshot_review()`](https://testthat.r-lib.org/reference/snapshot_accept.html)
and
[`testthat::snapshot_accept()`](https://testthat.r-lib.org/reference/snapshot_accept.html),
given the snapshot file's name and the directory of the feature files,
like `snapshot_accept("checkout-basket.feature", "tests/acceptance")`.

## Behavior

```
```

### Feature: Snapshots

`expect_snapshot()` in a step definition saves its snapshot next to the
feature files, in `_snaps`. Each feature file has a snapshot file of its
own, named after its path with its directories joined by `-`, as
testthat's `_snaps` has a file for each test file and a directory for
each variant: the snapshots of `checkout/basket.feature` are in
`_snaps/checkout-basket.feature.md`, and the snapshots of
`basket.feature.md`, a feature file in Markdown, are in
`_snaps/basket.feature.md`. A snapshot is named after its scenario.
Scenarios of the same name in a feature file are numbered, like the rows
of an outline without placeholders in its name: `Showing the basket (1)`
and `Showing the basket (2)`. A scenario of the same name added above
them renumbers them, so scenarios that take snapshots need names of
their own.

The snapshots are the same whether the feature files are run by
[`test()`](https://jakubsob.github.io/cucumber/dev/reference/test.md) or
by [`run()`](https://jakubsob.github.io/cucumber/dev/reference/run.md)
in a testthat file, so either can check the snapshots of the other.
Snapshots need the 3rd edition of testthat. A changed snapshot is
reviewed and accepted with
[`testthat::snapshot_review()`](https://testthat.r-lib.org/reference/snapshot_accept.html)
and
[`testthat::snapshot_accept()`](https://testthat.r-lib.org/reference/snapshot_accept.html),
given the snapshot file's name and the directory of the feature files,
like `snapshot_accept("checkout-basket.feature", "tests/acceptance")`, a
variant's with its directory, like
`snapshot_accept("linux/checkout-basket.feature", "tests/acceptance")`,
and `expect_snapshot_file()` files with a `/`, like
`snapshot_accept("checkout-basket.feature/", "tests/acceptance")`. The
message of a changed snapshot says which.

`expect_snapshot()` works in a step and in a
[`before()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md),
[`after()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md),
[`before_step()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
or
[`after_step()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
hook like in a testthat test, with `error`, `transform` and
`expect_snapshot_value()`. To skip the scenarios that take snapshots,
skip them in a
[`before_all()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
or
[`before()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
hook, not with `skip()` before
[`run()`](https://jakubsob.github.io/cucumber/dev/reference/run.md) in
its test file: testthat deletes the snapshot files of feature files that
a run of every test file didn't run.

#### Background:

- Given a package that uses the 3rd edition of testthat

#### Rule: A changed snapshot is accepted with testthat

##### Scenario Outline: A changed snapshot of \<feature\> is accepted with snapshot_accept("\<accepted\>"), with \<runner\>

- Given a feature file "\<feature\>" with a scenario "Showing the
  basket" that snapshots "1 apple"

- And I run the feature files with "\<runner\>"

- And the scenario "Showing the basket" of "\<feature\>" snapshots "2
  apples"

- When I run the feature files with "\<runner\>"

- Then the errors are

      [failure] Scenario: Showing the basket
      Step "the snapshot of "2 apples" matches" failed
      i Feature: <feature>:3
      i Scenario: Showing the basket
      i Step defined at: setup-snapshot-steps.R:9
      Snapshot of code has changed:
          old             | new
      [1] Code            | Code             [1]
      [2]   value         |   value          [2]
      [3] Output          | Output           [3]
      [4]   [1] "1 apple" -   [1] "2 apples" [4]
      * Run `testthat::snapshot_accept("<accepted>")` to accept the change.
      * Run `testthat::snapshot_review("<accepted>")` to review the change.

- When I run

      testthat::snapshot_accept("<accepted>", "tests/testthat")

- Then the snapshot file "\<snapshot file\>.md" has "2 apples" for
  "Showing the basket"

- And there is no snapshot file "\<snapshot file\>.new.md"

###### Examples:

|  |  |  |  |
|----|----|----|----|
| feature | accepted | snapshot file | runner |
| basket.feature | basket.feature | \_snaps/basket.feature | test() |
| basket.feature | basket.feature | \_snaps/basket.feature | run() |
| checkout/basket.feature | checkout-basket.feature | \_snaps/checkout-basket.feature | test() |
| checkout/basket.feature | checkout-basket.feature | \_snaps/checkout-basket.feature | run() |

#### Rule: Each feature file has a snapshot file of its own

##### Scenario Outline: The snapshot of \<feature\> is saved in \<snapshot file\> by \<runner\>

- Given a feature file "\<feature\>" with a scenario "Showing the
  basket" that snapshots "1 apple"

- When I run the feature files with "\<runner\>"

- Then the snapshot file "\<snapshot file\>" has "1 apple" for "Showing
  the basket"

###### Examples:

|                            |                                       |        |
|----------------------------|---------------------------------------|--------|
| feature                    | snapshot file                         | runner |
| basket.feature             | \_snaps/basket.feature.md             | test() |
| basket.feature             | \_snaps/basket.feature.md             | run()  |
| checkout/basket.feature    | \_snaps/checkout-basket.feature.md    | test() |
| checkout/basket.feature    | \_snaps/checkout-basket.feature.md    | run()  |
| shop/checkout/cart.feature | \_snaps/shop-checkout-cart.feature.md | test() |
| shop/checkout/cart.feature | \_snaps/shop-checkout-cart.feature.md | run()  |
| basket.feature.md          | \_snaps/basket.feature.md             | test() |
| basket.feature.md          | \_snaps/basket.feature.md             | run()  |

#### Rule: A snapshot is of a scenario

##### Scenario Outline: A snapshot in a \<hook\> hook is of its scenario, with \<runner\>

- Given a feature file "basket.feature" with a scenario "Showing the
  basket" that snapshots "1 apple"

- And a file named "tests/testthat/setup-hooks.R" with

      <hook>(function(context, scenario) expect_snapshot(cat("<hook> hook of", scenario$name)))

- And I run the feature files with "\<runner\>"

- When I run the feature files with "\<runner\>"

- Then the scenarios have these results:

  |                    |        |
  |--------------------|--------|
  | scenario           | status |
  | Showing the basket | passed |

- And the snapshot file "\_snaps/basket.feature.md" for "Showing the
  basket" has these lines:

      <hook> hook of Showing the basket

###### Examples:

|        |        |
|--------|--------|
| hook   | runner |
| before | test() |
| before | run()  |
| after  | test() |
| after  | run()  |

#### Rule: A snapshot is checked by the runs after the one that saved it

##### Scenario Outline: A snapshot saved by \<first\> is checked by \<second\>

- Given a feature file "basket.feature" with a scenario "Showing the
  basket" that snapshots "1 apple"

- And I run the feature files with "\<first\>"

- And the scenario "Showing the basket" of "basket.feature" snapshots "2
  apples"

- When I run the feature files with "\<second\>"

- Then the scenarios have these results:

  |                    |        |
  |--------------------|--------|
  | scenario           | status |
  | Showing the basket | failed |

- And the snapshot file "\_snaps/basket.feature.md" has "1 apple" for
  "Showing the basket"

- And the snapshot file "\_snaps/basket.feature.new.md" has "2 apples"
  for "Showing the basket"

###### Examples:

|        |        |
|--------|--------|
| first  | second |
| test() | test() |
| run()  | run()  |
| test() | run()  |
| run()  | test() |

#### Rule: A snapshot that isn't checked is kept

##### Scenario Outline: A scenario that stops before its snapshot keeps it, when "\<step\>", with \<runner\>

- Given a feature file "basket.feature" with a scenario "Showing the
  basket" that snapshots "1 apple"

- And I run the feature files with "\<runner\>"

- And the scenario "Showing the basket" of "basket.feature" starts with
  "\<step\>"

- When I run the feature files with "\<runner\>"

- Then the scenarios have these results:

  |                    |        |
  |--------------------|--------|
  | scenario           | status |
  | Showing the basket | failed |

- And the snapshot file "\_snaps/basket.feature.md" has "1 apple" for
  "Showing the basket"

###### Examples:

|                                |        |
|--------------------------------|--------|
| step                           | runner |
| it fails                       | test() |
| it fails                       | run()  |
| it doesn't meet an expectation | test() |
| it doesn't meet an expectation | run()  |

##### Scenario Outline: Snapshots of scenarios that didn't run are kept, with \<runner\>

- Given the steps that take snapshots

- And a file named "tests/testthat/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Showing the basket
      Then the snapshot of "1 apple" matches

    Scenario: Showing an empty basket
      Then the snapshot of "nothing" matches
  ```

- And I run the feature files with "\<runner\>"

- When I run the feature files with "\<runner\>" and the name "^Showing
  the basket\$"

- Then only these scenarios ran:

  |                    |
  |--------------------|
  | scenario           |
  | Showing the basket |

- And the snapshot file "\_snaps/basket.feature.md" has "nothing" for
  "Showing an empty basket"

###### Examples:

|        |
|--------|
| runner |
| test() |
| run()  |

#### Rule: Snapshots of scenarios that aren't in the feature file anymore are deleted

##### Scenario Outline: The snapshot of a renamed scenario is deleted, with \<runner\>

- Given a feature file "basket.feature" with a scenario "Showing the
  basket" that snapshots "1 apple"

- And I run the feature files with "\<runner\>"

- And the scenario "Showing the basket" of "basket.feature" is renamed
  "Showing the full basket"

- When I run the feature files with "\<runner\>"

- Then the snapshot file "\_snaps/basket.feature.md" has "1 apple" for
  "Showing the full basket"

- And the snapshot file "\_snaps/basket.feature.md" has no snapshot for
  "Showing the basket"

###### Examples:

|        |
|--------|
| runner |
| test() |
| run()  |

#### Rule: Snapshots are kept however the scenarios run

##### Scenario Outline: A retried scenario's snapshots are of its last attempt, with \<runner\>

- Given the steps that take snapshots

- And a file named "tests/testthat/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Showing the basket
      Then the snapshot of "1 apple" matches
  ```

- And I run the feature files with "\<runner\>"

- And a file named "tests/testthat/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Showing the basket
      Then the snapshot of "1 apple" matches
      And it fails the first time
  ```

- When I run the feature files with "\<runner\>" and retry = 1

- Then the scenarios have these results:

  |                    |        |          |
  |--------------------|--------|----------|
  | scenario           | status | attempts |
  | Showing the basket | passed | 2        |

- And the snapshot file "\_snaps/basket.feature.md" has 1 snapshot for
  "Showing the basket"

- And there is no snapshot file "\_snaps/basket.feature.new.md"

###### Examples:

|        |
|--------|
| runner |
| test() |
| run()  |

#### Rule: Snapshot files that aren't used are deleted, like in testthat

After a run of every scenario, the `expect_snapshot_file()` files that
weren't taken, like those of a scenario that failed before taking it,
the snapshot files of feature files that don't exist anymore, and
`_snaps/__cucumber__.md`, where cucumber 2 saved the snapshots of
[`test()`](https://jakubsob.github.io/cucumber/dev/reference/test.md),
are deleted.
[`testthat::announce_snapshot_file()`](https://testthat.r-lib.org/reference/expect_snapshot_file.html)
keeps a file that isn't taken. A run of some of the scenarios, like with
`filter`, `name`, `tags`, `features` or `dry_run`, or with `fail_fast`
after a failed scenario, and a run on CI delete nothing.

##### Background:

- Given the steps that take snapshots

- And a file named "tests/testthat/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Showing the basket
      Then the file snapshot "basket.txt" of "1 apple" matches
  ```

- And a file named "tests/testthat/checkout.feature" with

  ``` gherkin
  Feature: Checkout
    Scenario: Paying
      Then the file snapshot "receipt.txt" of "1 euro" matches
  ```

##### Scenario Outline: The snapshots of a deleted feature file are deleted, with \<runner\>

- Given I run the feature files with "\<runner\>"

- And the file "tests/testthat/checkout.feature" is deleted

- When I run the feature files with "\<runner\>"

- Then there is no file
  "tests/testthat/\_snaps/checkout.feature/receipt.txt"

- And there is no snapshot file "\_snaps/checkout.feature.md"

###### Examples:

|        |
|--------|
| runner |
| test() |
| run()  |

##### Scenario Outline: Snapshot files are kept by a run with \<selection\>, with \<runner\>

- Given I run the feature files with "\<runner\>"

- When I run the feature files with "\<runner\>" and \<selection\>

- Then the file "tests/testthat/\_snaps/checkout.feature/receipt.txt"
  has these lines:

      1 euro

###### Examples:

|                               |        |
|-------------------------------|--------|
| selection                     | runner |
| the filter "basket"           | test() |
| the filter "basket"           | run()  |
| the name "Showing"            | test() |
| the name "Showing"            | run()  |
| the tags "@basket"            | test() |
| the tags "@basket"            | run()  |
| the features "basket.feature" | test() |
| the features "basket.feature" | run()  |
| dry_run = TRUE                | test() |
| dry_run = TRUE                | run()  |

Source: `tests/acceptance/r-snapshots.feature`

## See also

[`vignette("testthat", package = "cucumber")`](https://jakubsob.github.io/cucumber/dev/articles/testthat.md)
compares snapshots of cucumber and testthat.
