Feature: Addition
  Scenario: Adding 2 integers
    When I add 1 and 1
    Then the result is 2
  Scenario: Adding integer and float
    When I add 1 and 1.1
    Then the result is 2.1
  Scenario: Adding float and float
    When I add 1.1 and 1.1
    Then the result is 2.2
  Scenario: Adding float and float with signs
    When I add +11.1 and +11.1
    Then the result is +22.2
  Scenario: Adding float and float of opposite signs
    When I add +11.11 and -11.1
    Then the result is +0.01
