Feature: Eating cucumbers
  Scenario: eat 5 out of 12
    Given there are 12 cucumbers
    When I eat 5 cucumbers
    Then I should have 7 cucumbers
