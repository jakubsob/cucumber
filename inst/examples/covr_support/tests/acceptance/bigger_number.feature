Feature: Bigger number
  Scenario: 1 is bigger than 0
    Given I have the number 1
    And I have the number 0
    When I compare the numbers
    Then the result should be 1
