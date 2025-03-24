# https://cucumber.io/docs/gherkin/reference/#scenario-outline
Feature: Eating
  Scenario Outline: eating
    Given there are <start> cucumbers
    When I eat <eat> cucumbers
    Then I should have <left> cucumbers

    Examples:
      | start | eat | left |
      |    12 |   5 |    7 |
      |    20 |   5 |   15 |

  Scenario Template: eating
    Given there are <start> cucumbers
    When I eat <eat> cucumbers
    Then I should have <left> cucumbers

    Examples:
      | start | eat | left |
      |    12 |   5 |    7 |
      |    20 |   5 |   15 |

  Scenario Template: eating
    Given there are <start> cucumbers
    Then I should have <left> cucumbers

    Examples:
      | start | left |
      | '5.6' | 5.6  |
      | "12"  | 12   |
