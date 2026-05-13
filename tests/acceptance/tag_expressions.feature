@tags
Feature: Tag expression filtering
  Scenario: Single tag expression
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/tagged.feature" with
      """
      Feature: Tags
        @fast
        Scenario: Fast scenario
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
      test("features", tags = "@fast")
      """
    Then it has 1 passed

  Scenario: Tag expression with AND operator
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/tagged.feature" with
      """
      Feature: Tags
        @smoke @fast
        Scenario: Smoke and fast scenario
          Given I have 1
          Then I get 1

        @smoke
        Scenario: Only smoke scenario
          Given I have 2
          Then I get 2

        @fast
        Scenario: Only fast scenario
          Given I have 3
          Then I get 3
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
      test("features", tags = "@smoke and @fast")
      """
    Then it has 1 passed

  Scenario: Tag expression with OR operator
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/tagged.feature" with
      """
      Feature: Tags
        @gui
        Scenario: GUI scenario
          Given I have 1
          Then I get 1

        @database
        Scenario: Database scenario
          Given I have 2
          Then I get 2

        @api
        Scenario: API scenario
          Given I have 3
          Then I get 3
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
      test("features", tags = "@gui or @database")
      """
    Then it has 2 passed

  Scenario: Tag expression with NOT operator
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/tagged.feature" with
      """
      Feature: Tags
        @wip
        Scenario: WIP scenario
          Given I have 1
          Then I get 1

        @wip @slow
        Scenario: WIP and slow scenario
          Given I have 2
          Then I get 2

        @fast
        Scenario: Fast scenario
          Given I have 3
          Then I get 3
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
      test("features", tags = "@wip and not @slow")
      """
    Then it has 1 passed

  Scenario: Tag expression with parentheses for precedence
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/tagged.feature" with
      """
      Feature: Tags
        @smoke @fast
        Scenario: Smoke and fast scenario
          Given I have 1
          Then I get 1

        @ui @fast
        Scenario: UI and fast scenario
          Given I have 2
          Then I get 2

        @smoke @slow
        Scenario: Smoke and slow scenario
          Given I have 3
          Then I get 3

        @ui @slow
        Scenario: UI and slow scenario
          Given I have 4
          Then I get 4
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
      test("features", tags = "(@smoke or @ui) and (not @slow)")
      """
    Then it has 2 passed

  Scenario: NOT operator excludes tagged scenarios
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/not-test.feature" with
      """
      Feature: NOT test
        @fast
        Scenario: Fast scenario
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
      test("features", tags = "not @slow")
      """
    Then it has 1 passed

  Scenario: Tags on Examples filter Scenario Outline runs
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/examples-tags.feature" with
      """
      Feature: Examples with tags
        Scenario Outline: Platform specific test
          Given I test on <platform>
          Then it works on <platform>

          @mobile
          Examples:
            | platform   |
            | "iOS"      |
            | "Android"  |

          @desktop
          Examples:
            | platform   |
            | "Mac"      |
            | "Windows"  |
      """
    And a file named "features/setup-steps.R" with
      """
      given("I test on {string}", function(platform, context) {
        context$platform <- platform
      })
      then("it works on {string}", function(platform, context) {
        expect_equal(context$platform, platform)
      })
      """
    When I run
      """
      test("features", tags = "@mobile")
      """
    Then it has 2 passed

  Scenario: Filtering Examples with tag expressions
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/examples-tags.feature" with
      """
      Feature: Examples with tag expressions
        Scenario Outline: Environment test
          Given I test value <value>
          Then I get value <value>

          @mobile @fast
          Examples:
            | value |
            | 1     |

          @desktop @fast
          Examples:
            | value |
            | 2     |

          @desktop @slow
          Examples:
            | value |
            | 3     |
      """
    And a file named "features/setup-steps.R" with
      """
      given("I test value {int}", function(value, context) {
        context$value <- value
      })
      then("I get value {int}", function(value, context) {
        expect_equal(context$value, value)
      })
      """
    When I run
      """
      test("features", tags = "@desktop and @fast")
      """
    Then it has 1 passed

  Scenario: Tags with special characters like issue tracker IDs
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/tagged.feature" with
      """
      Feature: Issue tracking
        @BJ-x98.77
        Scenario: First issue
          Given I have 1
          Then I get 1

        @BJ-z12.33
        Scenario: Second issue
          Given I have 2
          Then I get 2

        @JIRA-123
        Scenario: Third issue
          Given I have 3
          Then I get 3
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
      test("features", tags = "@BJ-x98.77 or @BJ-z12.33")
      """
    Then it has 2 passed
