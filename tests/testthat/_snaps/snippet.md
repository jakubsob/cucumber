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
        # when("I have {float} cucumbers in my basket", function(float, context) {
          pending()
        })

# format_step_snippet / suggests every parameter type that matches, the first one as code

    Code
      cat(snippet)
    Output
      given("I have {int} and {int} cucumbers", function(int, int2, context) {
      # given("I have {int} and {float} cucumbers", function(int, float, context) {
      # given("I have {float} and {int} cucumbers", function(float, int, context) {
      # given("I have {float} and {float} cucumbers", function(float, float2, context) {
        pending()
      })

# format_step_snippet / passes parameters in the order they are written

    Code
      cat(snippet)
    Output
      given("{string} has {float} and {string}", function(string, float, string2, context) {
        pending()
      })

# format_step_snippet / adds the data table and doc string arguments

    Code
      cat(snippet)
    Output
      when("I send", function(data_table, doc_string, context) {
        pending()
      })

# format_step_snippet / uses custom parameter types

    Code
      cat(snippet)
    Output
      given("a big {colour} ball", function(colour, context) {
        pending()
      })

