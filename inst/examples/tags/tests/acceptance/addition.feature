@smoke
Feature: Addition

  @fast
  Scenario: Adding two numbers
    Given I have 1
    And I have 2
    When I add them
    Then I get 3

  @slow
  Scenario: Adding three numbers
    Given I have 1
    And I have 2
    And I have 3
    When I add them
    Then I get 6
