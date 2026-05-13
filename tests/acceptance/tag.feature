@tags
Feature: Tags
  Scenario: Single tag runs only matching scenarios
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/tagged.feature" with
      """
      Feature: Addition
        @smoke
        Scenario: Smoke scenario
          Given I have 1
          Then I get 1

        @slow
        Scenario: Slow scenario
          Given I have 2
          Then I get 2
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
    When I run
      """
      test("features", tags = "smoke")
      """
    Then it has 1 passed

  Scenario: A scenario with multiple tags matches any of them
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/tagged.feature" with
      """
      Feature: Addition
        @db @fast
        Scenario: Smoke and fast scenario
          Given I have 1
          Then I get 1

        @fast
        Scenario: Slow scenario
          Given I have 2
          Then I get 2
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
    When I run
      """
      test("features", tags = "fast")
      """
    Then it has 2 passed

  Scenario: Feature-level tag is inherited by all its scenarios
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/tagged.feature" with
      """
      @smoke
      Feature: Addition
        Scenario: First scenario
          Given I have 1
          Then I get 1

        Scenario: Second scenario
          Given I have 2
          Then I get 2
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
    When I run
      """
      test("features", tags = "smoke")
      """
    Then it has 2 passed
