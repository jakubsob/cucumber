Feature: Guess the word
  Scenario: Maker starts a game
    When the Maker starts a game
    Then the Maker waits for a Breaker to join
  Scenario: Breaker joins a game
    Given the Maker has started a game with the word 'silky'
    When the Breaker joins the Maker's game
    Then the Breaker must guess a word with 5 characters
