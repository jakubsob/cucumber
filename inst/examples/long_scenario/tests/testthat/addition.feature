Feature: Addition
  Example: Addition should work for 3 numbers
    Given I have 1
    And I have 2
    And I have 3
    When I add them
    But I do nothing more
    Then I get 6
    And it's over

  Example: Addition should work for 5 numbers
    Given I have 1
    And I have 2
    And I have 3
    And I have 4
    And I have 5
    When I add them
    Then I get 15

  Example: Addition should work for 10 numbers
    Given I have 1
    * I have 1
    * I have 1
    * I have 1
    * I have 1
    * I have 1
    * I have 1
    * I have 1
    * I have 1
    * I have 1
    When I add them
    Then I get 10
