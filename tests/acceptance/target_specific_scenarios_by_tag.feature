Feature: Running scenarios by tag
  Run only the scenarios whose tags match a tag expression, like `test(tags = "@smoke and not @slow")`.
  A tag expression combines tags with `and`, `or`, `not` and parentheses.
  Scenarios inherit the tags of their Feature, and examples inherit the tags of their Examples.

  Background:
    Given a package
    And a file named "features/setup-steps.R" with
      """
      given("I have {int}", function(n, context) {
        context$value <- n
      })
      then("I get {int}", function(n, context) {
        expect_equal(context$value, n)
      })
      """

  Rule: A tag expression selects the scenarios to run

    Background:
      Given a file named "features/tagged.feature" with
        """
        Feature: Tagged
          @smoke @fast
          Scenario: Smoke and fast
            Given I have 1
            Then I get 1

          @smoke @slow
          Scenario: Smoke and slow
            Given I have 2
            Then I get 2

          @ui @fast
          Scenario: UI and fast
            Given I have 3
            Then I get 3

          @ui @slow
          Scenario: UI and slow
            Given I have 4
            Then I get 4

          Scenario: Untagged
            Given I have 5
            Then I get 5
        """

    Scenario: A single tag runs the scenarios that have it
      When I run
        """
        test("features", tags = "@smoke")
        """
      Then only these scenarios ran:
        | scenario       |
        | Smoke and fast |
        | Smoke and slow |

    Scenario: The @ of a tag can be left out
      When I run
        """
        test("features", tags = "smoke")
        """
      Then only these scenarios ran:
        | scenario       |
        | Smoke and fast |
        | Smoke and slow |

    Scenario: "and" runs the scenarios that have both tags
      When I run
        """
        test("features", tags = "@smoke and @fast")
        """
      Then only these scenarios ran:
        | scenario       |
        | Smoke and fast |

    Scenario: "or" runs the scenarios that have either tag
      When I run
        """
        test("features", tags = "@smoke or @ui")
        """
      Then only these scenarios ran:
        | scenario       |
        | Smoke and fast |
        | Smoke and slow |
        | UI and fast    |
        | UI and slow    |

    Scenario: "not" runs the scenarios that don't have the tag, untagged ones too
      When I run
        """
        test("features", tags = "not @slow")
        """
      Then only these scenarios ran:
        | scenario       |
        | Smoke and fast |
        | UI and fast    |
        | Untagged       |

    Scenario: Parentheses group parts of an expression
      When I run
        """
        test("features", tags = "(@smoke or @ui) and not @slow")
        """
      Then only these scenarios ran:
        | scenario       |
        | Smoke and fast |
        | UI and fast    |

  Rule: Scenarios inherit tags

    Scenario: A Feature's tags apply to all its scenarios
      Given a file named "features/tagged.feature" with
        """
        @smoke
        Feature: Tagged
          Scenario: First
            Given I have 1
            Then I get 1

          Scenario: Second
            Given I have 2
            Then I get 2
        """
      And a file named "features/untagged.feature" with
        """
        Feature: Untagged
          Scenario: Third
            Given I have 3
            Then I get 3
        """
      When I run
        """
        test("features", tags = "@smoke")
        """
      Then only these scenarios ran:
        | scenario |
        | First    |
        | Second   |

    Scenario: An Examples' tags apply to its examples
      Given a file named "features/outline.feature" with
        """
        Feature: Platforms
          Scenario Outline: Running on <n>
            Given I have <n>
            Then I get <n>

            @mobile
            Examples:
              | n |
              | 1 |
              | 2 |

            @desktop
            Examples:
              | n |
              | 3 |
        """
      When I run
        """
        test("features", tags = "@mobile")
        """
      Then only these scenarios ran:
        | scenario     |
        | Running on 1 |
        | Running on 2 |

  Rule: Tags can contain any character but whitespace

    Scenario: Tags like issue tracker IDs can be used in an expression
      Given a file named "features/tagged.feature" with
        """
        Feature: Issues
          @BJ-x98.77
          Scenario: First issue
            Given I have 1
            Then I get 1

          @JIRA-123
          Scenario: Second issue
            Given I have 2
            Then I get 2
        """
      When I run
        """
        test("features", tags = "@BJ-x98.77")
        """
      Then only these scenarios ran:
        | scenario    |
        | First issue |
