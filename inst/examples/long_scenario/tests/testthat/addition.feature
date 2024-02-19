Feature: Addition
  Example: Addition should work for 2 numbers
    Given I have 1
    And I have 2
    And I have 3
    When I add them
    But I do nothing more
    Then I get 6
    And it's over
