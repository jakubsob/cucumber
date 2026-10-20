Feature: Running tests with test()
  `test()` runs the feature files in `tests/acceptance`, or in the directory set in the `cucumber.path` option.
  Pass `path` to run another directory.

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
    And the output includes "1 scenario (1 passed)"

  Scenario: A directory without feature files is an error
    Given a file named "empty/setup-steps.R" with
      """
      given("a step", function(context) {})
      """
    When I run
      """
      test("empty", stop_on_failure = FALSE)
      """
    Then the error message includes "No feature files found."
