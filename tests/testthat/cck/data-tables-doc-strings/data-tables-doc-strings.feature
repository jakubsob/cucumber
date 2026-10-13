Feature: Data Tables and Doc Strings

  Steps can have both Data Table and Doc String as arguments at the same time

  Scenario: DataTable followed by DocString
    Given a step with a data table a doc string
      | hello |
      """
      world
      """

  Scenario: DocString followed by DataTable
    Given a step with a doc string a data table
      """
      hello
      """
      | world |
