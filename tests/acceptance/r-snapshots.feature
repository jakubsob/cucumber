Feature: Snapshots
  `expect_snapshot()` in a step definition saves its snapshot next to the feature files, in `_snaps`.
  Each feature file has a snapshot file of its own, named after its path with its directories joined by `-`,
  as testthat's `_snaps` has a file for each test file and a directory for each variant: the snapshots of
  `checkout/basket.feature` are in `_snaps/checkout-basket.feature.md`, and the snapshots of `basket.feature.md`,
  a feature file in Markdown, are in `_snaps/basket.feature.md`.
  A snapshot is named after its scenario. Scenarios of the same name in a feature file are numbered,
  like the rows of an outline without placeholders in its name: `Showing the basket (1)` and `Showing the basket (2)`.
  A scenario of the same name added above them renumbers them, so scenarios that take snapshots need names of their own.

  The snapshots are the same whether the feature files are run by `test()` or by `run()` in a testthat file,
  so either can check the snapshots of the other. Snapshots need the 3rd edition of testthat.
  A changed snapshot is reviewed and accepted with `testthat::snapshot_review()` and `testthat::snapshot_accept()`,
  given the snapshot file's name and the directory of the feature files, like
  `snapshot_accept("checkout-basket.feature", "tests/acceptance")`, a variant's with its directory, like
  `snapshot_accept("linux/checkout-basket.feature", "tests/acceptance")`, and `expect_snapshot_file()` files with
  a `/`, like `snapshot_accept("checkout-basket.feature/", "tests/acceptance")`. The message of a changed snapshot says which.

  `expect_snapshot()` works in a step and in a `before()`, `after()`, `before_step()` or `after_step()` hook like in a testthat
  test, with `error`, `transform` and `expect_snapshot_value()`. To skip the scenarios that take snapshots, skip them in a
  `before_all()` or `before()` hook, not with `skip()` before `run()` in its test file: testthat deletes the snapshot files of
  feature files that a run of every test file didn't run.

  Background:
    Given a package that uses the 3rd edition of testthat

  Rule: Snapshots need the 3rd edition of testthat

    Scenario Outline: A snapshot without the 3rd edition of testthat fails its step, with <runner>
      Given a feature file "basket.feature" with a scenario "Showing the basket" that snapshots "1 apple"
      And a file named "DESCRIPTION" with
        """
        Package: example
        Version: 0.1.0
        """
      When I run the feature files with "<runner>"
      Then the scenarios have these results:
        | scenario           | status |
        | Showing the basket | failed |
      And the errors are
        """
        [error] Scenario: Showing the basket
        Error: Step "the snapshot of "1 apple" matches" failed
        i Feature: basket.feature
        i Scenario: Showing the basket
        i Step defined at: setup-snapshot-steps.R:9
        Caused by error in `edition_require()`:
        ! `expect_snapshot()` requires the 3rd edition.
        """

      Examples:
        | runner |
        | test() |
        | run()  |

  Rule: A changed snapshot is accepted with testthat

    Scenario Outline: A changed snapshot of <feature> is accepted with snapshot_accept("<accepted>"), with <runner>
      Given a feature file "<feature>" with a scenario "Showing the basket" that snapshots "1 apple"
      And I run the feature files with "<runner>"
      And the scenario "Showing the basket" of "<feature>" snapshots "2 apples"
      When I run the feature files with "<runner>"
      Then the errors are
        """
        [failure] Scenario: Showing the basket
        Step "the snapshot of "2 apples" matches" failed
        i Feature: <feature>
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
        """
      When I run
        """
        testthat::snapshot_accept("<accepted>", "tests/testthat")
        """
      Then the snapshot file "<snapshot file>.md" has "2 apples" for "Showing the basket"
      And there is no snapshot file "<snapshot file>.new.md"

      Examples:
        | feature                 | accepted                | snapshot file                   | runner |
        | basket.feature          | basket.feature          | _snaps/basket.feature          | test() |
        | basket.feature          | basket.feature          | _snaps/basket.feature          | run()  |
        | checkout/basket.feature | checkout-basket.feature | _snaps/checkout-basket.feature | test() |
        | checkout/basket.feature | checkout-basket.feature | _snaps/checkout-basket.feature | run()  |

    Scenario Outline: A changed variant snapshot of <feature> is accepted with snapshot_accept("<accepted>"), with <runner>
      Given the steps that take snapshots
      And a file named "tests/testthat/<feature>" with
        """
        Feature: Basket
          Scenario: Showing the basket
            Then the snapshot of "1 apple" for "linux" matches
        """
      And I run the feature files with "<runner>"
      And a file named "tests/testthat/<feature>" with
        """
        Feature: Basket
          Scenario: Showing the basket
            Then the snapshot of "2 apples" for "linux" matches
        """
      When I run the feature files with "<runner>"
      Then the errors are
        """
        [failure] Scenario: Showing the basket
        Step "the snapshot of "2 apples" for "linux" matches" failed
        i Feature: <feature>
        i Scenario: Showing the basket
        i Step defined at: setup-snapshot-steps.R:10
        Snapshot of code has changed (variant 'linux'):
            old             | new
        [1] Code            | Code             [1]
        [2]   value         |   value          [2]
        [3] Output          | Output           [3]
        [4]   [1] "1 apple" -   [1] "2 apples" [4]
        * Run `testthat::snapshot_accept("<accepted>")` to accept the change.
        * Run `testthat::snapshot_review("<accepted>")` to review the change.
        """
      When I run
        """
        testthat::snapshot_accept("<accepted>", "tests/testthat")
        """
      Then the snapshot file "_snaps/<accepted>.md" has "2 apples" for "Showing the basket"
      And there is no snapshot file "_snaps/<accepted>.new.md"

      Examples:
        | feature                 | accepted                      | runner |
        | basket.feature          | linux/basket.feature          | test() |
        | basket.feature          | linux/basket.feature          | run()  |
        | checkout/basket.feature | linux/checkout-basket.feature | test() |
        | checkout/basket.feature | linux/checkout-basket.feature | run()  |

    Scenario Outline: A changed snapshot of <feature> is reviewed with snapshot_review("<reviewed>"), with <runner>
      Given a feature file "<feature>" with a scenario "Showing the basket" that snapshots "1 apple"
      And I run the feature files with "<runner>"
      And the scenario "Showing the basket" of "<feature>" snapshots "2 apples"
      And I run the feature files with "<runner>"
      When I run
        """
        testthat::with_mocked_bindings(
          testthat::snapshot_review("<reviewed>", "tests/testthat"),
          check_installed = function(...) invisible(),
          review_app = function(name, old_path, new_path, ...) writeLines(c(name, old_path, new_path), "reviewed.txt"),
          .package = "testthat"
        )
        """
      Then the file "reviewed.txt" has these lines:
        """
        <name>
        tests/testthat/<snapshot file>.md
        tests/testthat/<snapshot file>.new.md
        """

      Examples:
        | feature                 | reviewed                | name                       | snapshot file                  | runner |
        | basket.feature          | basket.feature          | basket.feature.md          | _snaps/basket.feature          | test() |
        | basket.feature          | basket.feature          | basket.feature.md          | _snaps/basket.feature          | run()  |
        | checkout/basket.feature | checkout-basket.feature | checkout-basket.feature.md | _snaps/checkout-basket.feature | test() |
        | checkout/basket.feature | checkout-basket.feature | checkout-basket.feature.md | _snaps/checkout-basket.feature | run()  |

    Scenario Outline: A changed file snapshot of <feature> is accepted with snapshot_accept("<accepted>"), with <runner>
      Given the steps that take snapshots
      And a file named "tests/testthat/<feature>" with
        """
        Feature: Basket
          Scenario: Showing the basket
            Then the file snapshot "basket.txt" of "1 apple" matches
        """
      And a file named "tests/testthat/basket.feature" with
        """
        Feature: Basket at the top
          Scenario: Showing the basket at the top
            Then the file snapshot "basket.txt" of "1 apple at the top" matches
        """
      And I run the feature files with "<runner>"
      And a file named "tests/testthat/<feature>" with
        """
        Feature: Basket
          Scenario: Showing the basket
            Then the file snapshot "basket.txt" of "2 apples" matches
        """
      When I run the feature files with "<runner>"
      Then the errors are
        """
        [failure] Scenario: Showing the basket
        Step "the file snapshot "basket.txt" of "2 apples" matches" failed
        i Feature: <feature>
        i Scenario: Showing the basket
        i Step defined at: setup-snapshot-steps.R:17
        Snapshot of `file` has changed.
        Differences:
            old     | new
        [1] 1 apple - 2 apples [1]
        * Run `testthat::snapshot_accept("<accepted>")` to accept the change.
        * Run `testthat::snapshot_review("<accepted>")` to review the change.
        """
      When I run
        """
        testthat::snapshot_accept("<accepted>", "tests/testthat")
        """
      Then the file "tests/testthat/_snaps/<accepted>basket.txt" has these lines:
        """
        2 apples
        """
      And there is no file "tests/testthat/_snaps/<accepted>basket.new.txt"

      Examples:
        | feature                    | accepted                    | runner |
        | checkout/basket.feature    | checkout-basket.feature/    | test() |
        | checkout/basket.feature    | checkout-basket.feature/    | run()  |
        | shop/checkout/cart.feature | shop-checkout-cart.feature/ | test() |
        | shop/checkout/cart.feature | shop-checkout-cart.feature/ | run()  |

  Rule: Each feature file has a snapshot file of its own

    Scenario Outline: The snapshot of <feature> is saved in <snapshot file> by <runner>
      Given a feature file "<feature>" with a scenario "Showing the basket" that snapshots "1 apple"
      When I run the feature files with "<runner>"
      Then the snapshot file "<snapshot file>" has "1 apple" for "Showing the basket"

      Examples:
        | feature                  | snapshot file                      | runner |
        | basket.feature           | _snaps/basket.feature.md          | test() |
        | basket.feature           | _snaps/basket.feature.md          | run()  |
        | checkout/basket.feature  | _snaps/checkout-basket.feature.md | test() |
        | checkout/basket.feature  | _snaps/checkout-basket.feature.md | run()  |
        | shop/checkout/cart.feature | _snaps/shop-checkout-cart.feature.md | test() |
        | shop/checkout/cart.feature | _snaps/shop-checkout-cart.feature.md | run()  |
        | basket.feature.md        | _snaps/basket.feature.md          | test() |
        | basket.feature.md        | _snaps/basket.feature.md          | run()  |

    Scenario Outline: Feature files of the same name in different directories don't share snapshots, with <runner>
      Given a feature file "basket.feature" with a scenario "Showing the basket" that snapshots "1 apple"
      And a feature file "checkout/basket.feature" with a scenario "Showing the basket" that snapshots "2 apples"
      When I run the feature files with "<runner>"
      Then the snapshot file "_snaps/basket.feature.md" has "1 apple" for "Showing the basket"
      And the snapshot file "_snaps/checkout-basket.feature.md" has "2 apples" for "Showing the basket"

      Examples:
        | runner |
        | test() |
        | run()  |

    Scenario Outline: <first> and <second> would share a snapshot file and stop the run, with <runner>
      Given a feature file "<first>" with a scenario "Showing the basket" that snapshots "1 apple"
      And a feature file "<second>" with a scenario "Showing the basket" that snapshots "2 apples"
      When I run the feature files with "<runner>"
      Then the errors are
        """
        [error]
        <message>
        x `<first>` and `<second>` save their snapshots in `_snaps/<snapshot file>`.
        i Rename one of them.
        """
      And there is no snapshot file "_snaps/<snapshot file>"

      Examples:
        | first                    | second                  | snapshot file               | runner | message                                   |
        | basket.feature          | basket.feature.md       | basket.feature.md          | test() | Feature files share a snapshot file.        |
        | basket.feature          | basket.feature.md       | basket.feature.md          | run()  | Error: Feature files share a snapshot file. |
        | checkout/basket.feature | checkout-basket.feature | checkout-basket.feature.md | test() | Feature files share a snapshot file.        |
        | checkout/basket.feature | checkout-basket.feature | checkout-basket.feature.md | run()  | Error: Feature files share a snapshot file. |

    Scenario Outline: A feature file in a directory named like a variant has snapshots of its own, with <runner>
      Given the steps that take snapshots
      And a file named "tests/testthat/basket.feature" with
        """
        Feature: Basket
          Scenario: Showing the basket
            Then the snapshot of "1 apple" for "linux" matches
        """
      And a file named "tests/testthat/linux/basket.feature" with
        """
        Feature: Basket on linux
          Scenario: Showing the basket on linux
            Then the snapshot of "2 apples" matches
        """
      And I run the feature files with "<runner>"
      When I run the feature files with "<runner>"
      Then the scenarios have these results:
        | scenario                    | status |
        | Showing the basket          | passed |
        | Showing the basket on linux | passed |
      And the snapshot file "_snaps/linux/basket.feature.md" has "1 apple" for "Showing the basket"
      And the snapshot file "_snaps/linux-basket.feature.md" has "2 apples" for "Showing the basket on linux"

      Examples:
        | runner |
        | test() |
        | run()  |

  Rule: A snapshot is of a scenario

    Scenario Outline: A snapshot in a before_all hook is an error, with <runner>
      Given a feature file "basket.feature" with a scenario "Showing the basket" that snapshots "1 apple"
      And a file named "tests/testthat/setup-hooks.R" with
        """
        before_all(function(context) expect_snapshot(1))
        """
      When I run the feature files with "<runner>"
      Then the errors are
        """
        [error]
        <headline>
        i Hook defined at: setup-hooks.R:1
        Caused by error:
        ! `testthat::expect_snapshot()` can only be called in a step, or in a `before()`, `after()`, `before_step()` or `after_step()` hook.
        """

      Examples:
        | runner | headline                        |
        | test() | Hook `before_all()` failed        |
        | run()  | Error: Hook `before_all()` failed |

    Scenario Outline: A snapshot in an after_all hook is an error, after the scenarios took theirs, with <runner>
      Given a feature file "basket.feature" with a scenario "Showing the basket" that snapshots "1 apple"
      And a file named "tests/testthat/setup-hooks.R" with
        """
        after_all(function(context) expect_snapshot(1))
        """
      When I run the feature files with "<runner>"
      Then the errors are
        """
        [warning] Scenario: Showing the basket
        Adding new snapshot:
        Code
          value
        Output
          [1] "1 apple"

        [error]
        <headline>
        i Hook defined at: setup-hooks.R:1
        Caused by error:
        ! `testthat::expect_snapshot()` can only be called in a step, or in a `before()`, `after()`, `before_step()` or `after_step()` hook.
        """

      Examples:
        | runner | headline                        |
        | test() | Hook `after_all()` failed        |
        | run()  | Error: Hook `after_all()` failed |

    Scenario Outline: A snapshot in a <hook> hook is of its scenario, with <runner>
      Given a feature file "basket.feature" with a scenario "Showing the basket" that snapshots "1 apple"
      And a file named "tests/testthat/setup-hooks.R" with
        """
        <hook>(function(context, scenario) expect_snapshot(cat("<hook> hook of", scenario$name)))
        """
      And I run the feature files with "<runner>"
      When I run the feature files with "<runner>"
      Then the scenarios have these results:
        | scenario           | status |
        | Showing the basket | passed |
      And the snapshot file "_snaps/basket.feature.md" for "Showing the basket" has these lines:
        """
        <hook> hook of Showing the basket
        """

      Examples:
        | hook   | runner |
        | before | test() |
        | before | run()  |
        | after  | test() |
        | after  | run()  |

    Scenario Outline: A snapshot in a <hook> hook is of its scenario, with <runner>
      Given a feature file "basket.feature" with a scenario "Showing the basket" that snapshots "1 apple"
      And a file named "tests/testthat/setup-hooks.R" with
        """
        <hook>(function(context, step) expect_snapshot(cat("<hook> hook of", step$text)))
        """
      And I run the feature files with "<runner>"
      When I run the feature files with "<runner>"
      Then the scenarios have these results:
        | scenario           | status |
        | Showing the basket | passed |
      And the snapshot file "_snaps/basket.feature.md" for "Showing the basket" has these lines:
        """
        <hook> hook of the snapshot of "1 apple" matches
        """

      Examples:
        | hook        | runner |
        | before_step | test() |
        | before_step | run()  |
        | after_step  | test() |
        | after_step  | run()  |

  Rule: expect_snapshot() records like in a testthat test

    Scenario Outline: Snapshots of an error, a transformed output and a value are checked, with <runner>
      Given the steps that take snapshots
      And a file named "tests/testthat/basket.feature" with
        """
        Feature: Basket
          Scenario: Showing the basket
            Then the snapshot of the error "Out of apples" matches
            And the snapshot of the temporary directory matches
            And the snapshot of the value "1 apple" matches
        """
      And I run the feature files with "<runner>"
      When I run the feature files with "<runner>"
      Then the scenarios have these results:
        | scenario           | status |
        | Showing the basket | passed |
      And the snapshot file "_snaps/basket.feature.md" for "Showing the basket" has these lines:
        """
        ! Out of apples
        <tempdir>
        "1 apple"
        """

      Examples:
        | runner |
        | test() |
        | run()  |

  Rule: A snapshot is checked by the runs after the one that saved it

    Scenario Outline: A snapshot saved by <first> is checked by <second>
      Given a feature file "basket.feature" with a scenario "Showing the basket" that snapshots "1 apple"
      And I run the feature files with "<first>"
      And the scenario "Showing the basket" of "basket.feature" snapshots "2 apples"
      When I run the feature files with "<second>"
      Then the scenarios have these results:
        | scenario           | status |
        | Showing the basket | failed |
      And the snapshot file "_snaps/basket.feature.md" has "1 apple" for "Showing the basket"
      And the snapshot file "_snaps/basket.feature.new.md" has "2 apples" for "Showing the basket"

      Examples:
        | first   | second |
        | test() | test() |
        | run()  | run()  |
        | test() | run()  |
        | run()  | test() |

    Scenario Outline: A snapshot that didn't change passes, with <runner>
      Given a feature file "basket.feature" with a scenario "Showing the basket" that snapshots "1 apple"
      And I run the feature files with "<runner>"
      When I run the feature files with "<runner>"
      Then the scenarios have these results:
        | scenario           | status |
        | Showing the basket | passed |
      And there is no snapshot file "_snaps/basket.feature.new.md"

      Examples:
        | runner |
        | test() |
        | run()  |

    Scenario Outline: A new snapshot fails on CI, with <runner>
      Given a feature file "basket.feature" with a scenario "Showing the basket" that snapshots "1 apple"
      When I run the feature files with "<runner>" on CI
      Then the scenarios have these results:
        | scenario           | status |
        | Showing the basket | failed |

      Examples:
        | runner |
        | test() |
        | run()  |

    Scenario Outline: A snapshot of a scenario named with characters of more than one byte is checked, with <runner>
      Given a feature file "basket.feature" with a scenario "Koszyk z jabłkiem" that snapshots "1 jabłko"
      And I run the feature files with "<runner>"
      When I run the feature files with "<runner>"
      Then the scenarios have these results:
        | scenario          | status |
        | Koszyk z jabłkiem | passed |
      And the snapshot file "_snaps/basket.feature.md" has "1 jabłko" for "Koszyk z jabłkiem"

      Examples:
        | runner |
        | test() |
        | run()  |

    Scenario: A snapshot is checked when the test file that runs the feature file runs alone
      Given a feature file "basket.feature" with a scenario "Showing the basket" that snapshots "1 apple"
      And a file named "tests/testthat/test-other.R" with
        """
        test_that("other", succeed())
        """
      And I run the feature files with "run()"
      And the scenario "Showing the basket" of "basket.feature" snapshots "2 apples"
      When I run
        """
        withr::with_envvar(
          c(NOT_CRAN = "true", CI = NA, TESTTHAT = NA),
          testthat::test_file("tests/testthat/test-acceptance.R", reporter = "silent", stop_on_failure = FALSE)
        )
        """
      Then the snapshot file "_snaps/basket.feature.md" has "1 apple" for "Showing the basket"
      And the snapshot file "_snaps/basket.feature.new.md" has "2 apples" for "Showing the basket"

  Rule: A snapshot that isn't checked is kept

    Scenario Outline: A scenario that stops before its snapshot keeps it, when "<step>", with <runner>
      Given a feature file "basket.feature" with a scenario "Showing the basket" that snapshots "1 apple"
      And I run the feature files with "<runner>"
      And the scenario "Showing the basket" of "basket.feature" starts with "<step>"
      When I run the feature files with "<runner>"
      Then the scenarios have these results:
        | scenario           | status |
        | Showing the basket | failed |
      And the snapshot file "_snaps/basket.feature.md" has "1 apple" for "Showing the basket"

      Examples:
        | step                           | runner |
        | it fails                       | test() |
        | it fails                       | run()  |
        | it doesn't meet an expectation | test() |
        | it doesn't meet an expectation | run()  |

    Scenario Outline: A scenario skipped by a before() hook keeps its snapshots, with <runner>
      Given a feature file "basket.feature" with a scenario "Showing the basket" that snapshots "1 apple"
      And I run the feature files with "<runner>"
      And a file named "tests/testthat/setup-hooks.R" with
        """
        before(function(context, scenario) skip("Not now"))
        """
      When I run the feature files with "<runner>"
      Then the scenarios have these results:
        | scenario           | status  |
        | Showing the basket | skipped |
      And the snapshot file "_snaps/basket.feature.md" has "1 apple" for "Showing the basket"

      Examples:
        | runner |
        | test() |
        | run()  |

    Scenario Outline: A snapshot isn't checked on CRAN and is kept, with <runner>
      Given a feature file "basket.feature" with a scenario "Showing the basket" that snapshots "1 apple"
      And I run the feature files with "<runner>"
      And the scenario "Showing the basket" of "basket.feature" snapshots "2 apples"
      When I run the feature files with "<runner>" on CRAN
      Then the scenarios have these results:
        | scenario           | status |
        | Showing the basket | passed |
      And the snapshot file "_snaps/basket.feature.md" has "1 apple" for "Showing the basket"
      And there is no snapshot file "_snaps/basket.feature.new.md"

      Examples:
        | runner |
        | test() |
        | run()  |

    Scenario Outline: Scenarios skipped by a before_all() hook keep their snapshots, with <runner>
      Given the steps that take snapshots
      And a file named "tests/testthat/basket.feature" with
        """
        Feature: Basket
          Scenario: Showing the basket
            Then the file snapshot "basket.txt" of "1 apple" matches
        """
      And I run the feature files with "<runner>"
      And a file named "tests/testthat/setup-hooks.R" with
        """
        before_all(function() skip("Not now"))
        """
      When I run the feature files with "<runner>"
      Then the scenarios have these results:
        | scenario           | status  |
        | Showing the basket | skipped |
      And the file "tests/testthat/_snaps/basket.feature/basket.txt" has these lines:
        """
        1 apple
        """

      Examples:
        | runner |
        | test() |
        | run()  |

    Scenario Outline: Snapshots of scenarios that didn't run are kept, with <runner>
      Given the steps that take snapshots
      And a file named "tests/testthat/basket.feature" with
        """
        Feature: Basket
          Scenario: Showing the basket
            Then the snapshot of "1 apple" matches

          Scenario: Showing an empty basket
            Then the snapshot of "nothing" matches
        """
      And I run the feature files with "<runner>"
      When I run the feature files with "<runner>" and the name "^Showing the basket$"
      Then only these scenarios ran:
        | scenario           |
        | Showing the basket |
      And the snapshot file "_snaps/basket.feature.md" has "nothing" for "Showing an empty basket"

      Examples:
        | runner |
        | test() |
        | run()  |

    Scenario Outline: Snapshots of feature files that didn't run are kept, with <runner>
      Given a feature file "basket.feature" with a scenario "Showing the basket" that snapshots "1 apple"
      And a feature file "checkout.feature" with a scenario "Paying" that snapshots "1 euro"
      And I run the feature files with "<runner>"
      When I run the feature files with "<runner>" and the filter "basket"
      Then only these scenarios ran:
        | scenario           |
        | Showing the basket |
      And the snapshot file "_snaps/checkout.feature.md" has "1 euro" for "Paying"

      Examples:
        | runner |
        | test() |
        | run()  |

  Rule: Snapshots of scenarios that aren't in the feature file anymore are deleted

    Scenario Outline: The snapshot of a renamed scenario is deleted, with <runner>
      Given a feature file "basket.feature" with a scenario "Showing the basket" that snapshots "1 apple"
      And I run the feature files with "<runner>"
      And the scenario "Showing the basket" of "basket.feature" is renamed "Showing the full basket"
      When I run the feature files with "<runner>"
      Then the snapshot file "_snaps/basket.feature.md" has "1 apple" for "Showing the full basket"
      And the snapshot file "_snaps/basket.feature.md" has no snapshot for "Showing the basket"

      Examples:
        | runner |
        | test() |
        | run()  |

  Rule: Snapshots are kept however the scenarios run

    Scenario Outline: A scenario's snapshot doesn't depend on which scenarios run, with <runner>
      Given the steps that take snapshots
      And a file named "tests/testthat/basket.feature" with
        """
        Feature: Basket
          Scenario Outline: Showing the basket
            Then the snapshot of "<items>" matches

            Examples:
              | items    |
              | 1 apple  |
              | 2 apples |
        """
      And I run the feature files with "<runner>"
      When I run the feature files with "<runner>" and the features "basket.feature:8"
      Then the scenarios have these results:
        | scenario           | status |
        | Showing the basket | passed |
      And the snapshot file "_snaps/basket.feature.md" has "1 apple" for "Showing the basket (1)"
      And the snapshot file "_snaps/basket.feature.md" has "2 apples" for "Showing the basket (2)"
      And there is no snapshot file "_snaps/basket.feature.new.md"

      Examples:
        | runner |
        | test() |
        | run()  |

    Scenario Outline: Snapshots are kept when the scenarios of a feature don't run one after another, with <runner>
      Given the steps that take snapshots
      And a file named "tests/testthat/basket.feature" with
        """
        Feature: Basket
          Scenario: Showing the basket
            Then the snapshot of "1 apple" matches

          Scenario: Showing an empty basket
            Then the snapshot of "nothing" matches
        """
      And a file named "tests/testthat/checkout.feature" with
        """
        Feature: Checkout
          Scenario: Paying
            Then the snapshot of "1 euro" matches

          Scenario: Paying nothing
            Then the snapshot of "0 euro" matches
        """
      When I run the feature files with "<runner>" and the order "random:2"
      Then these scenarios ran in this order:
        | scenario                |
        | Showing the basket      |
        | Paying                  |
        | Showing an empty basket |
        | Paying nothing          |
      And the snapshot file "_snaps/basket.feature.md" has "1 apple" for "Showing the basket"
      And the snapshot file "_snaps/basket.feature.md" has "nothing" for "Showing an empty basket"
      And the snapshot file "_snaps/checkout.feature.md" has "1 euro" for "Paying"
      And the snapshot file "_snaps/checkout.feature.md" has "0 euro" for "Paying nothing"

      Examples:
        | runner |
        | test() |
        | run()  |

    Scenario Outline: A retried scenario's snapshots are of its last attempt, with <runner>
      Given the steps that take snapshots
      And a file named "tests/testthat/basket.feature" with
        """
        Feature: Basket
          Scenario: Showing the basket
            Then the snapshot of "1 apple" matches
        """
      And I run the feature files with "<runner>"
      And a file named "tests/testthat/basket.feature" with
        """
        Feature: Basket
          Scenario: Showing the basket
            Then the snapshot of "1 apple" matches
            And it fails the first time
        """
      When I run the feature files with "<runner>" and retry = 1
      Then the scenarios have these results:
        | scenario           | status | attempts |
        | Showing the basket | passed | 2        |
      And the snapshot file "_snaps/basket.feature.md" has 1 snapshot for "Showing the basket"
      And there is no snapshot file "_snaps/basket.feature.new.md"

      Examples:
        | runner |
        | test() |
        | run()  |

    Scenario Outline: Snapshot files aren't run as feature files, with <runner>
      Given the steps that take snapshots
      And a file named "tests/testthat/basket.feature" with
        """
        Feature: Basket
          Scenario: Showing the basket
            Then the snapshot of "1 apple" matches

          Scenario: Showing an empty basket
            Then the snapshot of "nothing" matches
        """
      And I run the feature files with "<runner>"
      When I run the feature files with "<runner>"
      Then only these scenarios ran:
        | scenario                |
        | Showing the basket      |
        | Showing an empty basket |

      Examples:
        | runner |
        | test() |
        | run()  |

    Scenario: Changed snapshots of a feature split across test files are all kept
      Given the steps that take snapshots
      And a file named "tests/testthat/basket.feature" with
        """
        Feature: Basket
          @full
          Scenario: Showing the basket
            Then the snapshot of "1 apple" matches

          @empty
          Scenario: Showing an empty basket
            Then the snapshot of "nothing" matches
        """
      And a file named "tests/testthat/test-full.R" with
        """
        run(tags = "@full")
        """
      And a file named "tests/testthat/test-empty.R" with
        """
        run(tags = "@empty")
        """
      And I run
        """
        withr::with_envvar(c(NOT_CRAN = NA, CI = NA, TESTTHAT = NA), testthat::test_local(reporter = "silent", stop_on_failure = FALSE))
        """
      And a file named "tests/testthat/basket.feature" with
        """
        Feature: Basket
          @full
          Scenario: Showing the basket
            Then the snapshot of "2 apples" matches

          @empty
          Scenario: Showing an empty basket
            Then the snapshot of "still nothing" matches
        """
      When I run
        """
        withr::with_envvar(c(NOT_CRAN = NA, CI = NA, TESTTHAT = NA), testthat::test_local(reporter = "silent", stop_on_failure = FALSE))
        """
      Then the snapshot file "_snaps/basket.feature.new.md" has "2 apples" for "Showing the basket"
      And the snapshot file "_snaps/basket.feature.new.md" has "still nothing" for "Showing an empty basket"
      And the snapshot file "_snaps/basket.feature.md" has "1 apple" for "Showing the basket"
      And the snapshot file "_snaps/basket.feature.md" has "nothing" for "Showing an empty basket"

  Rule: Variants and file snapshots are saved next to the feature's snapshot file

    Scenario Outline: A variant's snapshot of a feature in a subdirectory, with <runner>
      Given the steps that take snapshots
      And a file named "tests/testthat/checkout/basket.feature" with
        """
        Feature: Basket
          Scenario: Showing the basket
            Then the snapshot of "1 apple" for "linux" matches
        """
      When I run the feature files with "<runner>"
      Then the snapshot file "_snaps/linux/checkout-basket.feature.md" has "1 apple" for "Showing the basket"

      Examples:
        | runner |
        | test() |
        | run()  |

    Scenario Outline: A file snapshot is saved in the directory of the feature's snapshots, with <runner>
      Given the steps that take snapshots
      And a file named "tests/testthat/basket.feature" with
        """
        Feature: Basket
          Scenario: Showing the basket
            Then the file snapshot "basket.txt" of "1 apple" matches
        """
      And I run the feature files with "<runner>"
      When I run the feature files with "<runner>"
      Then the file "tests/testthat/_snaps/basket.feature/basket.txt" has these lines:
        """
        1 apple
        """

      Examples:
        | runner |
        | test() |
        | run()  |

  Rule: Snapshot files that aren't used are deleted, like in testthat
    After a run of every scenario, the `expect_snapshot_file()` files that weren't taken, like those of a
    scenario that failed before taking it, the snapshot files of feature files that don't exist anymore, and
    `_snaps/__cucumber__.md`, where cucumber 2 saved the snapshots of `test()`, are deleted. `testthat::announce_snapshot_file()` keeps a file that isn't taken. A run of some of the
    scenarios, like with `filter`, `name`, `tags`, `features` or `dry_run`, or with `fail_fast` after a
    failed scenario, and a run on CI delete nothing.

    Background:
      Given the steps that take snapshots
      And a file named "tests/testthat/basket.feature" with
        """
        Feature: Basket
          Scenario: Showing the basket
            Then the file snapshot "basket.txt" of "1 apple" matches
        """
      And a file named "tests/testthat/checkout.feature" with
        """
        Feature: Checkout
          Scenario: Paying
            Then the file snapshot "receipt.txt" of "1 euro" matches
        """

    Scenario Outline: A file snapshot that isn't taken anymore is deleted, with <runner>
      Given I run the feature files with "<runner>"
      And a file named "tests/testthat/basket.feature" with
        """
        Feature: Basket
          Scenario: Showing the basket
            Then the snapshot of "1 apple" matches
        """
      When I run the feature files with "<runner>"
      Then there is no file "tests/testthat/_snaps/basket.feature/basket.txt"

      Examples:
        | runner |
        | test() |
        | run()  |

    Scenario Outline: An announced file snapshot is kept when its scenario fails before taking it, with <runner>
      Given I run the feature files with "<runner>"
      And a file named "tests/testthat/basket.feature" with
        """
        Feature: Basket
          Scenario: Showing the basket
            Given the file snapshot "basket.txt" is announced
            And it fails
            Then the file snapshot "basket.txt" of "1 apple" matches
        """
      When I run the feature files with "<runner>"
      Then the scenarios have these results:
        | scenario           | status |
        | Showing the basket | failed |
        | Paying             | passed |
      And the file "tests/testthat/_snaps/basket.feature/basket.txt" has these lines:
        """
        1 apple
        """

      Examples:
        | runner |
        | test() |
        | run()  |

    Scenario Outline: The snapshots of a deleted feature file are deleted, with <runner>
      Given I run the feature files with "<runner>"
      And the file "tests/testthat/checkout.feature" is deleted
      When I run the feature files with "<runner>"
      Then there is no file "tests/testthat/_snaps/checkout.feature/receipt.txt"
      And there is no snapshot file "_snaps/checkout.feature.md"

      Examples:
        | runner |
        | test() |
        | run()  |

    Scenario Outline: The snapshot file of cucumber 2, _snaps/__cucumber__.md, is deleted, with <runner>
      Given a file named "tests/testthat/_snaps/__cucumber__.md" with
        """
        # Scenario: Showing the basket

            Code
              value
            Output
              [1] "1 apple"
        """
      When I run the feature files with "<runner>"
      Then there is no snapshot file "_snaps/__cucumber__.md"

      Examples:
        | runner |
        | test() |
        | run()  |

    Scenario Outline: Snapshot files are kept by a run with <selection>, with <runner>
      Given I run the feature files with "<runner>"
      When I run the feature files with "<runner>" and <selection>
      Then the file "tests/testthat/_snaps/checkout.feature/receipt.txt" has these lines:
        """
        1 euro
        """

      Examples:
        | selection                       | runner |
        | the filter "basket"             | test() |
        | the filter "basket"             | run()  |
        | the name "Showing"              | test() |
        | the name "Showing"              | run()  |
        | the features "basket.feature"   | test() |
        | the features "basket.feature"   | run()  |
        | dry_run = TRUE                  | test() |
        | dry_run = TRUE                  | run()  |

    Scenario Outline: Snapshot files are kept by a run() that stops before it starts, with <selection>, with <runner>
      Given I run the feature files with "<runner>"
      When I run the feature files with "<runner>" and <selection>
      Then the file "tests/testthat/_snaps/basket.feature/basket.txt" has these lines:
        """
        1 apple
        """
      And the file "tests/testthat/_snaps/checkout.feature/receipt.txt" has these lines:
        """
        1 euro
        """

      Examples:
        | selection                        | runner |
        | the features "missing.feature"   | test() |
        | the features "missing.feature"   | run()  |
        | the filter "nothing matches"     | test() |
        | the filter "nothing matches"     | run()  |

    Scenario Outline: Snapshot files of the scenarios skipped by `fail_fast` are kept, with <runner>
      Given I run the feature files with "<runner>"
      And a file named "tests/testthat/basket.feature" with
        """
        Feature: Basket
          Scenario: Showing the basket
            Given it fails
        """
      When I run the feature files with "<runner>" and fail_fast = TRUE
      Then the file "tests/testthat/_snaps/checkout.feature/receipt.txt" has these lines:
        """
        1 euro
        """

      Examples:
        | runner |
        | test() |
        | run()  |

    Scenario Outline: Snapshot files are kept by a run on CI, with <runner>
      Given I run the feature files with "<runner>"
      And the file "tests/testthat/checkout.feature" is deleted
      When I run the feature files with "<runner>" on CI
      Then the file "tests/testthat/_snaps/checkout.feature/receipt.txt" has these lines:
        """
        1 euro
        """

      Examples:
        | runner |
        | test() |
        | run()  |

  Rule: run() deletes the unused snapshot files of feature files outside of tests/testthat
    testthat deletes the unused snapshot files of `tests/testthat` only, so `run("../acceptance")`
    deletes those of the feature files in `tests/acceptance`.

    Scenario: The snapshots of a deleted feature file in another directory are deleted by run()
      Given the steps that take snapshots
      And a file named "tests/acceptance/basket.feature" with
        """
        Feature: Basket
          Scenario: Showing the basket
            Then the file snapshot "basket.txt" of "1 apple" matches
        """
      And a file named "tests/acceptance/checkout.feature" with
        """
        Feature: Checkout
          Scenario: Paying
            Then the file snapshot "receipt.txt" of "1 euro" matches
        """
      And a file named "tests/testthat/test-acceptance.R" with
        """
        run("../acceptance")
        """
      And I run
        """
        withr::with_envvar(c(NOT_CRAN = NA, CI = NA, TESTTHAT = NA), testthat::test_local(reporter = "silent"))
        """
      And the file "tests/acceptance/checkout.feature" is deleted
      When I run
        """
        withr::with_envvar(c(NOT_CRAN = NA, CI = NA, TESTTHAT = NA), testthat::test_local(reporter = "silent"))
        """
      Then the file "tests/acceptance/_snaps/basket.feature/basket.txt" has these lines:
        """
        1 apple
        """
      And there is no file "tests/acceptance/_snaps/checkout.feature/receipt.txt"

  Rule: test() in a testthat file tells testthat of the snapshot files of the feature files next to it
    testthat deletes the snapshot files of `tests/testthat` that its run didn't use, so `test(".")` in a testthat file
    of `tests/testthat` tells testthat which snapshot files its feature files use. In a parallel testthat run, the
    process that deletes them can't be told, so it's an error, like `run()`.

    Scenario: test() in a testthat file keeps the snapshots of the feature files next to it
      Given a file named "tests/testthat/setup-steps.R" with
        """
        then("the snapshot of {string} matches", function(value, context) expect_snapshot(value))
        """
      And a file named "tests/testthat/basket.feature" with
        """
        Feature: Basket
          Scenario: Showing the basket
            Then the snapshot of "1 apple" matches
        """
      And a file named "tests/testthat/test-acceptance.R" with
        """
        cucumber::test(".", reporter = NULL)
        """
      And I run
        """
        withr::with_envvar(c(NOT_CRAN = NA, CI = NA, TESTTHAT = NA), testthat::test_local(reporter = "silent"))
        """
      When I run
        """
        withr::with_envvar(c(NOT_CRAN = NA, CI = NA, TESTTHAT = NA), testthat::test_local(reporter = "silent"))
        """
      Then the snapshot file "_snaps/basket.feature.md" has "1 apple" for "Showing the basket"

    Scenario: test() of the directory of a parallel testthat run is an error
      Given a file named "tests/testthat/setup-steps.R" with
        """
        then("the snapshot of {string} matches", function(value, context) expect_snapshot(value))
        """
      And a file named "tests/testthat/basket.feature" with
        """
        Feature: Basket
          Scenario: Showing the basket
            Then the snapshot of "1 apple" matches
        """
      And a file named "tests/testthat/test-acceptance.R" with
        """
        cucumber::test(".", reporter = NULL)
        """
      When I run
        """
        withr::with_envvar(
          c(TESTTHAT_IS_PARALLEL = "true"),
          testthat::test_local(reporter = "silent", stop_on_failure = FALSE)
        )
        """
      Then the errors are
        """
        [error]
        Error: `test()` of the directory of a parallel testthat run isn't supported.
        i Set `Config/testthat/parallel: false` in DESCRIPTION, or keep the feature files in another directory, like `test("../acceptance")`.
        """
