Feature: Running tests with test()
  `test()` runs the feature files in `tests/acceptance`, or in the directory set in the `cucumber.path` option.
  Pass `path` to run another directory. A mistake in an argument is an error that names the argument.

  Background:
    Given a package
    And a file named "tests/acceptance/addition.feature" with
      """
      Feature: Addition
        Scenario: Adding in tests/acceptance
          Given I have 1
          Then I get 1
      """
    And a file named "features/addition.feature" with
      """
      Feature: Addition
        Scenario: Adding in features
          Given I have 1
          Then I get 1
      """
    And a file named "tests/acceptance/setup-steps.R" with
      """
      given("I have {int}", function(n, context) {
        context$value <- n
      })
      then("I get {int}", function(n, context) {
        expect_equal(context$value, n)
      })
      """
    And a file named "features/setup-steps.R" with
      """
      given("I have {int}", function(n, context) {
        context$value <- n
      })
      then("I get {int}", function(n, context) {
        expect_equal(context$value, n)
      })
      """

  @rd
  Scenario: Feature files in tests/acceptance are run by default
    When I run
      """
      test()
      """
    Then only these scenarios ran:
      | scenario                   |
      | Adding in tests/acceptance |

  @rd
  Scenario: Feature files are run from the directory set in the cucumber.path option
    When I run
      """
      withr::with_options(list(cucumber.path = "features"), test())
      """
    Then only these scenarios ran:
      | scenario           |
      | Adding in features |

  Scenario: A directory without feature files is an error
    Given a file named "empty/setup-steps.R" with
      """
      given("a step", function(context) {})
      """
    When I run it and it fails
      """
      test("empty")
      """
    Then it fails with
      """
      Error:
      ! Test failures.
      Caused by error:
      ! No feature files found.
      i Add `.feature` files describing your scenarios.
      """

  Rule: A mistake in an argument is an error that names the argument

    Scenario: A directory that doesn't exist is an error
      When I run it and it fails
        """
        test("missing")
        """
      Then it fails with
        """
        Error:
        ! `path` must be a directory.
        x "missing" doesn't exist.
        """

    Scenario Outline: An argument with <case> is an error
      When I run it and it fails
        """
        test("features", <argument>)
        """
      Then it fails with
        """
        Error:
        ! <message>
        """

      Examples:
        | case                             | argument             | message                                                        |
        | a flag that isn't TRUE or FALSE  | dry_run = "yes"      | `dry_run` must be `TRUE` or `FALSE`.                           |
        | a negative number of retries     | retry = -1           | `retry` must be a whole number of 0 or more, like `retry = 2`. |
        | several filters                  | filter = c("a", "b") | `filter` must be one regular expression.                       |
        | an env that isn't an environment | env = "features"     | `env` must be an environment, or `NULL`.                       |

    Scenario Outline: A mistake in an argument of <function>() is an error
      When I run it and it fails
        """
        <function>("features", filter = c("a", "b"))
        """
      Then it fails with
        """
        Error:
        ! `filter` must be one regular expression.
        """

      Examples:
        | function    |
        | test        |
        | run         |
        | features_rd |

    Scenario Outline: A mistake in <argument> is an error even with stop_on_failure = FALSE
      Nothing runs, so there are no results to report.

      When I run it and it fails
        """
        test("features", <argument> = <value>, stop_on_failure = FALSE)
        """
      Then it fails with
        """
        Error:
        ! <message>
        """

      Examples:
        | argument | value       | message                                                                                    |
        | dry_run  | "yes"       | `dry_run` must be `TRUE` or `FALSE`.                                                       |
        | tags     | "@a AND @b" | Tag expression "@a AND @b" could not be parsed because of syntax error: Expected operator. |

    Scenario: An invalid regular expression in name is an error with the reason
      When I run it and it fails
        """
        test("features", name = c("^Adding", "("))
        """
      Then it fails with
        """
        Error:
        ! `name` must be valid regular expressions.
        x invalid regular expression '(', reason 'Missing ')''
        """

    Scenario: An invalid regular expression in filter is an error with the reason
      When I run it and it fails
        """
        test("features", filter = "(")
        """
      Then it fails with
        """
        Error:
        ! `filter` must be a valid regular expression.
        x invalid regular expression '(', reason 'Missing ')''
        """

    Scenario: Feature files that aren't paths are an error
      When I run it and it fails
        """
        test("features", features = 12)
        """
      Then it fails with
        """
        Error:
        ! `features` must be paths of feature files.
        i Give a path with the lines of its scenarios to run only them, like `"basket.feature:12"`.
        """
