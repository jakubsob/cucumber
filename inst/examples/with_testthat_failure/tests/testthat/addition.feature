Feature: Addition
  Scenario: Adding 2 integers
    When I add 1 and 1
    Then the result is 2
  Scenario: Adding integer and float
    When I add 1 and 1.1
    Then the result is 5
  Scenario: Adding float and float
    When I add 1.1 and 1.1
    Then the result is 5
