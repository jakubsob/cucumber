Feature: Running scenarios by tag
  Run only the scenarios whose tags match a tag expression, like `test(tags = "@smoke and not @slow")`.
  A tag expression combines tags with `and`, `or`, `not` and parentheses, like the official
  cucumber/tag-expressions. Tags are written with their `@`, and `and`, `or` and `not` are lowercase.
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

    Scenario: A tag without its @ doesn't match
      When I run
        """
        test("features", tags = "smoke or @ui")
        """
      Then only these scenarios ran:
        | scenario    |
        | UI and fast |
        | UI and slow |

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

    Scenario: An empty tag expression runs every scenario
      When I run
        """
        test("features", tags = "")
        """
      Then it has 5 passed

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

  Rule: A tag in an expression is everything up to whitespace or a parenthesis

    A backslash escapes a parenthesis, a whitespace or a backslash in a tag: `@wip\(x\)` matches the tag `@wip(x)`.
    In an R string the backslash itself is escaped: `tags = "@wip\\(x\\)"`.

    Background:
      Given a file named "features/tagged.feature" with
        """
        Feature: Issues
          @BJ-x98.77
          Scenario: Issue tracker ID
            Given I have 1
            Then I get 1

          @team:payments
          Scenario: Team
            Given I have 2
            Then I get 2

          @and-more
          Scenario: Starts like an operator
            Given I have 3
            Then I get 3

          @wip(x)
          Scenario: With parentheses
            Given I have 4
            Then I get 4
        """

    Scenario: Tags with punctuation can be used in an expression
      When I run
        """
        test("features", tags = "@BJ-x98.77 or @team:payments or @and-more")
        """
      Then only these scenarios ran:
        | scenario                |
        | Issue tracker ID        |
        | Team                    |
        | Starts like an operator |

    Scenario: Parentheses in a tag are escaped with a backslash
      When I run
        """
        test("features", tags = "@wip\\(x\\)")
        """
      Then only these scenarios ran:
        | scenario         |
        | With parentheses |

  Rule: An invalid tag expression is an error

    Scenario Outline: An invalid tag expression is an error, <case>
      Given a file named "features/tagged.feature" with
        """
        Feature: Tagged
          @smoke
          Scenario: Smoke
            Given I have 1
            Then I get 1
        """
      When I run
        """
        test("features", tags = "<expression>", stop_on_failure = FALSE)
        """
      Then it has 1 errors
      And the error message includes "Tag expression \"<expression>\" could not be parsed because of syntax error: <message>"

      Examples:
        | case               | expression     | message              |
        | missing operator   | @a @b          | Expected operator.   |
        | missing operand    | @a and         | Expected operand.    |
        | unmatched (        | ( @a and @b    | Unmatched (.         |
        | unmatched )        | @a )           | Unmatched ).         |

    Scenario: A backslash before anything but a parenthesis, a backslash or whitespace is an error
      Given a file named "features/tagged.feature" with
        """
        Feature: Tagged
          @smoke
          Scenario: Smoke
            Given I have 1
            Then I get 1
        """
      When I run
        """
        test("features", tags = "@a\\b", stop_on_failure = FALSE)
        """
      Then it has 1 errors
      And the error message includes "could not be parsed because of syntax error: Illegal escape before \"b\"."
