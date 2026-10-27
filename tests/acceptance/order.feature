Feature: Order
  Scenarios run in the order they are defined: feature files in order of their path, and the scenarios
  of each file from top to bottom. With `order`, they run in reverse or in random order instead,
  which shows scenarios that pass only after another one left something behind.

  Background:
    Given a package
    And a file named "features/a.feature" with
      """
      Feature: A
        Scenario: A1
          Given a step

        Scenario: A2
          Given a step
      """
    And a file named "features/b.feature" with
      """
      Feature: B
        Scenario: B1
          Given a step

        Scenario: B2
          Given a step
      """
    And a file named "features/setup-steps.R" with
      """
      given("a step", function(context) {})
      """

  Scenario: Scenarios run in the order they are defined
    When I run
      """
      test("features")
      """
    Then the scenarios have these results:
      | scenario | status |
      | A1       | passed |
      | A2       | passed |
      | B1       | passed |
      | B2       | passed |

  @rd
  Scenario: Scenarios of all features run in reverse order
    When I run
      """
      test("features", order = "reverse")
      """
    Then the scenarios have these results:
      | scenario | status |
      | B2       | passed |
      | B1       | passed |
      | A2       | passed |
      | A1       | passed |

  @rd
  Scenario: Scenarios of all features run in the random order of a seed
    When I run
      """
      test("features", order = "random:1")
      """
    Then the scenarios have these results:
      | scenario | status |
      | A1       | passed |
      | B1       | passed |
      | B2       | passed |
      | A2       | passed |

  Scenario: A random order leaves the random numbers of the session as they were
    When I run
      """
      set.seed(42)
      test("features", order = "random:1")
      cat("next:", runif(1), "\n")
      set.seed(42)
      cat("expected:", runif(1), "\n")
      """
    Then the output includes "next: 0.914806"
    And the output includes "expected: 0.914806"

  @rd
  Scenario: A random order without a seed shows the seed to run the same order again
    When I run
      """
      test("features", order = "random")
      """
    Then the output includes "Running scenarios in random order. Use `order = \"random:"

  Scenario Outline: An unknown order is an error
    When I run it and it fails
      """
      test("features", order = "<order>")
      """
    Then it fails with
      """
      Error:
      ! Unknown order "<order>".
      i Use "defined", "reverse", "random" or "random:<seed>", like "random:1234", with a seed of up to 2147483647.
      """

    Examples:
      | order             |
      | shuffled          |
      | random:2147483648 |
