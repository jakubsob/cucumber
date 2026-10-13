Feature: Examples Tables - With Many Undefined Steps
  The replacement pattern used in scenario outlines does not influence how steps
  are matched. The replacement pattern is replaced, and step definitions are
  matched against that text. Because of that the following results in several
  undefined steps for each example and suggested snippets to implement them.

  Scenario Outline: Eating cucumbers
    Given there are <start> cucumbers
    When I eat <eat> cucumbers
    Then I should have <left> cucumbers

    @undefined
    Examples: These are undefined because many of the values are not an {int}
      | start | eat    | left  |
      | pear  | 1      | apple |
      | pear  | banana | 12    |
      | 0     | banana | apple |
      | pear  | banana | apple |
