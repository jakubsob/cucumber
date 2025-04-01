Feature: Column multiplication
  Scenario: Multiplying selected column
    Given I have a table
      | x | y | z |
      | 1 | 3 | 5 |
      | 2 | 4 | 6 |
    When I multiply x column by 2
    Then I should see the following table
      | x | y | z |
      | 2 | 3 | 5 |
      | 4 | 4 | 6 |
