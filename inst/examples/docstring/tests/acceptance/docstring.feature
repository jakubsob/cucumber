Feature: Docstrings
  Scenario: It is possible to pass docstring to a step
    Given I have a docstring
      ```
      My docstring

      It has multiple lines

      I will remove this one
      ```
    When I remove line that contains 'I will remove this one'
    And I remove trailing empty lines
    Then the docstring looks like this
      """
      My docstring

      It has multiple lines
      """
