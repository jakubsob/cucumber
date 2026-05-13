# preview / should preview a simple feature

    Code
      print(result)
    Output
      Preview of 2 test case(s):
      
      [1] Pickle: Maker starts a game
        ID: pickle-<id>
        Steps:
          Step the Maker starts a game
          Step the Maker waits for a Breaker to join
      
      [2] Pickle: Breaker joins a game
        ID: pickle-<id>
        Steps:
          Step the Maker has started a game with the word 'silky'
          Step the Breaker joins the Maker's game
          Step the Breaker must guess a word with 5 characters

# preview / should preview with file filter

    Code
      print(result)
    Output
      Preview of 5 test case(s):
      
      [1] Pickle: Adding 2 integers
        ID: pickle-<id>
        Steps:
          Step I add 1 and 1
          Step the result is 2
      
      [2] Pickle: Adding integer and float
        ID: pickle-<id>
        Steps:
          Step I add 1 and 1.1
          Step the result is 2.1
      
      [3] Pickle: Adding float and float
        ID: pickle-<id>
        Steps:
          Step I add 1.1 and 1.1
          Step the result is 2.2
      
      [4] Pickle: Adding float and float with signs
        ID: pickle-<id>
        Steps:
          Step I add +11.1 and +11.1
          Step the result is +22.2
      
      [5] Pickle: Adding float and float of opposite signs
        ID: pickle-<id>
        Steps:
          Step I add +11.11 and -11.1
          Step the result is +0.01

# preview / should preview scenario outlines with expanded examples

    Code
      print(result)
    Output
      Preview of 6 test case(s):
      
      [1] Pickle: eating (Example 1)
        ID: pickle-<id>
        Steps:
          Step there are 12 cucumbers
          Step I eat 5 cucumbers
          Step I should have 7 cucumbers
      
      [2] Pickle: eating (Example 2)
        ID: pickle-<id>
        Steps:
          Step there are 20 cucumbers
          Step I eat 5 cucumbers
          Step I should have 15 cucumbers
      
      [3] Pickle: eating (Example 1)
        ID: pickle-<id>
        Steps:
          Step there are 12 cucumbers
          Step I eat 5 cucumbers
          Step I should have 7 cucumbers
      
      [4] Pickle: eating (Example 2)
        ID: pickle-<id>
        Steps:
          Step there are 20 cucumbers
          Step I eat 5 cucumbers
          Step I should have 15 cucumbers
      
      [5] Pickle: eating (Example 1)
        ID: pickle-<id>
        Steps:
          Step there are '5.6' cucumbers
          Step I should have 5.6 cucumbers
      
      [6] Pickle: eating (Example 2)
        ID: pickle-<id>
        Steps:
          Step there are "12" cucumbers
          Step I should have 12 cucumbers

# preview / should preview with tag filter

    Code
      print(result)
    Output
      Preview of 1 test case(s):
      
      [1] Pickle: Adding two numbers  [@smoke @fast]
        ID: pickle-<id>
        Steps:
          Step I have 1
          Step I have 2
          Step I add them
          Step I get 3

# preview / should preview with complex tag expression

    Code
      print(result)
    Output
      Preview of 1 test case(s):
      
      [1] Pickle: Adding two numbers  [@smoke @fast]
        ID: pickle-<id>
        Steps:
          Step I have 1
          Step I have 2
          Step I add them
          Step I get 3

# preview / should show step details including data tables

    Code
      print(result)
    Output
      Preview of 1 test case(s):
      
      [1] Pickle: Multiplying selected column
        ID: pickle-<id>
        Steps:
          Step I have a table
            <data table>
          Step I multiply x column by 2
          Step I should see the following table
            <data table>

# preview / should show step details including docstrings

    Code
      print(result)
    Output
      Preview of 1 test case(s):
      
      [1] Pickle: It is possible to pass docstring to a step
        ID: pickle-<id>
        Steps:
          Step I have a docstring
            <docstring>
          Step I remove line that contains 'I will remove this one'
          Step I remove trailing empty lines
          Step the docstring looks like this
            <docstring>

