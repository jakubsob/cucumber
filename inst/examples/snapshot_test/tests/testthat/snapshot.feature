Feature: Snapshot
  Scenario: Snapshotting code output
    Given I have a text
      """
      Hello, world!
      """
    Then the output should be saved in a snapshot
