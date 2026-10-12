Feature: Gherkin
  Feature files are parsed like the official Gherkin parser does it.
  A line's meaning comes from its keyword, not from its indentation.

  Background:
    Given a package

  Scenario: Indentation doesn't matter
    Given a file named "features/indent.feature" with
      """
      Feature: Indentation
      Scenario: Flat
      Given I have 1
      Then I should have 1
          Scenario: Tabs and a step deeper than the previous one
      	Given I have 1
      		Then I should have 1
      """
    And a file named "features/setup-steps.R" with
      """
      given("I have {int}", function(n, context) {
        context$n <- n
      })
      then("I should have {int}", function(n, context) {
        expect_equal(context$n, n)
      })
      """
    When I run
      """
      test("features")
      """
    Then it passes
    And it has 2 passed

  Scenario: A feature without scenarios runs nothing
    Given a file named "features/empty.feature" with
      """
      Feature: Not written yet
        Scenarios will come later.
      """
    And a file named "features/setup-steps.R" with
      """
      given("a step", function(context) {})
      """
    When I run
      """
      test("features")
      """
    Then it has 0 passed
    And the output doesn't include "Feature: Not written yet"

  Scenario: An empty feature file runs nothing
    Given a file named "features/empty.feature" with
      """

      """
    And a file named "features/setup-steps.R" with
      """
      given("a step", function(context) {})
      """
    When I run
      """
      test("features")
      """
    Then it has 0 passed

  Scenario: A scenario without steps passes
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Not written yet
      """
    When I run
      """
      test("features")
      """
    Then it passes
    And it has 1 passed

  Scenario Outline: <keyword> can be used instead of Feature
    Given a file named "features/eating.feature" with
      """
      <keyword>: Eating
        Scenario: Eat a cucumber
          Given a step
      """
    And a file named "features/setup-steps.R" with
      """
      given("a step", function(context) {})
      """
    When I run
      """
      test("features")
      """
    Then it passes
    And the output includes "<keyword>: Eating"

    Examples:
      | keyword       |
      | Ability       |
      | Business Need |
