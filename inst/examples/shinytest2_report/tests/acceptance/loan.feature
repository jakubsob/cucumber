Feature: Loan calculator
  Scenario: Splitting a loan into monthly payments
    Given I open the loan calculator
    When I borrow 1200 over 12 months
    Then I see "Monthly payment: 100"

  Scenario: Asking for at least 1 month
    Given I open the loan calculator
    When I borrow 1200 over 0 months
    Then I see "Pick at least 1 month"
