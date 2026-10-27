@rd
Feature: Usage reporter
  `CucumberUsageReporter` prints how each step definition was used when the run ends, like Cucumber's
  `usage` formatter. Each step definition is listed with the mean duration of its steps and where it's
  defined, followed by the steps it matched, the slowest first, with where they are. A step definition
  that no step matched is `UNUSED`. It finds slow steps, and step definitions to remove.

  Background:
    Given a package
    And a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add apples
          Given an empty basket
          When I add 2 apples
          And I add 1 apples

        Scenario: Wait
          Given an empty basket
          When I wait
      """
    And a file named "features/setup-steps.R" with
      """
      given("an empty basket", function(context) {})
      when("I add {int} apples", function(n, context) {})
      when("I wait", function(context) Sys.sleep(0.1))
      when("I remove {int} apples", function(n, context) {})
      """

  Scenario: Each step definition is listed with the steps it matched
    A dry run doesn't run the steps, so they have no duration.

    When I run
      """
      test("features", dry_run = TRUE, reporter = CucumberUsageReporter$new())
      """
    Then the output includes
      """
      Step definition / Step  Duration  Location
      an empty basket         -         setup-steps.R:1
        an empty basket       -         basket.feature:3
        an empty basket       -         basket.feature:8
      I add {int} apples      -         setup-steps.R:2
        I add 2 apples        -         basket.feature:4
        I add 1 apples        -         basket.feature:5
      I wait                  -         setup-steps.R:3
        I wait                -         basket.feature:9
      I remove {int} apples   UNUSED    setup-steps.R:4
      """

  Scenario: A regular expression is shown between slashes
    Given a file named "features/setup-steps.R" with
      """
      given("an empty basket", function(context) {})
      when("^I add (\\d+) apples$", function(n, context) {})
      when("I wait", function(context) {})
      """
    When I run
      """
      test("features", dry_run = TRUE, reporter = CucumberUsageReporter$new())
      """
    Then the output includes
      """
      Step definition / Step  Duration  Location
      an empty basket         -         setup-steps.R:1
        an empty basket       -         basket.feature:3
        an empty basket       -         basket.feature:8
      /^I add (\d+) apples$/  -         setup-steps.R:2
        I add 2 apples        -         basket.feature:4
        I add 1 apples        -         basket.feature:5
      I wait                  -         setup-steps.R:3
        I wait                -         basket.feature:9
      """

  Scenario: A run without step definitions has no usage to show
    Given a file named "features/setup-steps.R" with
      """
      """
    When I run
      """
      test("features", dry_run = TRUE, reporter = CucumberUsageReporter$new())
      """
    Then the output includes "No step definitions"

  Scenario: The slowest step definitions come first, and the unused ones last
    When I run
      """
      test("features", reporter = CucumberUsageReporter$new())
      """
    Then the output includes lines matching these patterns in order:
      """
      ^I wait +[0-9.]+ms +setup-steps.R:3$
      ^I wait +[0-9.]+ms +basket.feature:9$
      ^I remove \{int\} apples +UNUSED +setup-steps.R:4$
      """

  Scenario: Only the five slowest steps of a step definition are listed
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add apples
          When I add 1 apples
          And I add 2 apples
          And I add 3 apples
          And I add 4 apples
          And I add 5 apples
          And I add 6 apples
          And I add 7 apples
      """
    When I run
      """
      test("features", dry_run = TRUE, reporter = CucumberUsageReporter$new())
      """
    Then the output includes
      """
      I add {int} apples      -         setup-steps.R:2
        I add 1 apples        -         basket.feature:3
        I add 2 apples        -         basket.feature:4
        I add 3 apples        -         basket.feature:5
        I add 4 apples        -         basket.feature:6
        I add 5 apples        -         basket.feature:7
        ... 2 more
      """

  Scenario: An ambiguous step isn't a use of its step definitions
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add apples
          When I add 2 apples
      """
    And a file named "features/setup-steps.R" with
      """
      when("I add {int} apples", function(n, context) {})
      when("I add {float} apples", function(n, context) {})
      """
    When I run
      """
      test("features", dry_run = TRUE, reporter = CucumberUsageReporter$new())
      """
    Then the output includes
      """
      I add {int} apples      UNUSED    setup-steps.R:1
      I add {float} apples    UNUSED    setup-steps.R:2
      """
