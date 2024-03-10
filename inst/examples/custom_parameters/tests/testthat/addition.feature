Feature: Addition
  Scenario: I can't add a color to a number
    Given I have a color red
    Given I have a person named 'John Doe'
    When I add them
    Then 🤯
  Scenario: I can add two numbers in scientific notation
    Given I have a number 1e3
    And I have a number 1e3
    When I add them
    Then I get 2e3
