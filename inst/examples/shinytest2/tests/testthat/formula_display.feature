Feature: Formula display
  Scenario: Selecting Transmission as the grouping variable
    Given I am on the main page
    When I select 'Transmission' variable
    Then the formula display should show 'mpg ~ am'

  Scenario: Selecting Gears as the grouping variable
    Given I am on the main page
    When I select 'Gears' variable
    Then the formula display should show 'mpg ~ gear'
