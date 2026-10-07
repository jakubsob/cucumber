# match_single_step snippet / uses the step keyword and indents the snippet

    Code
      cat(conditionMessage(matched$error))
    Output
      No step found for: "it passes"
      i Add a step definition:
        then("it passes", function(context) {
          pending()
        })

# match_single_step snippet / keeps parameter placeholders in the snippet

    Code
      cat(conditionMessage(matched$error))
    Output
      No step found for: "I have 5 cucumbers in my basket"
      i Add a step definition:
        when("I have {int} cucumbers in my basket", function(int, context) {
          pending()
        })

