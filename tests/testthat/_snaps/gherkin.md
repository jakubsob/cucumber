# parse_gherkin / reports every error with the file path

    Code
      parse_gherkin(lines, uri = "features/broken.feature")
    Condition
      Error:
      ! Can't parse features/broken.feature
      x (4:5): expected: #EOF, #TableRow, #DocStringSeparator, #StepLine, #TagLine, #ExamplesLine, #ScenarioLine, #RuleLine, #Comment, #Empty, got 'not a step'
      x (6:5): expected: #EOF, #TableRow, #DocStringSeparator, #StepLine, #TagLine, #ExamplesLine, #ScenarioLine, #RuleLine, #Comment, #Empty, got 'also not a step'

