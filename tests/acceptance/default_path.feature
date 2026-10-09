Feature: Default path
  `test()` without `path` runs feature files from the directory set in the `cucumber.path` option.

  Background:
    Given a package
    And a file named "features/addition.feature" with
      """
      Feature: Addition
        Scenario: Adding numbers
          Given I have 1
          Then I get 1
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

  Scenario: Feature files are run from the directory set in the option
    When I run
      """
      withr::with_options(list(cucumber.path = "features"), test())
      """
    Then the output includes "1 scenario (1 passed)"
