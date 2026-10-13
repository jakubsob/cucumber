Feature: Doc strings with expressions
  Doc strings can be combined with Cucumber expressions. The arguments from the
  Cucumber expression are provided before the doc string.

  Scenario: a doc string with a cucumber expression
    Given a "Cucumber" with a doc string:
    """
    Cucumis sativus
    """
