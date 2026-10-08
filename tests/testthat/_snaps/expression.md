# expression_to_pattern / should fail on an undefined parameter type

    Code
      expression_to_pattern("I like {color}", parameters)
    Condition
      Error:
      ! This Cucumber Expression has a problem at column 8:
      
      I like {color}
             ^-----^
      Undefined parameter type 'color'.
      Please register a ParameterType for 'color'

# expression_to_pattern / should fail on invalid expressions like Cucumber Expressions

    Code
      expression_to_pattern("three ((very) blind) mice", parameters)
    Condition
      Error:
      ! This Cucumber Expression has a problem at column 8:
      
      three ((very) blind) mice
             ^----^
      An optional may not contain an other optional.
      If you did not mean to use an optional type you can use '\(' to escape the '('. For more complicated expressions consider using a regular expression instead.
      In an R string, double each backslash: "\\(".

---

    Code
      expression_to_pattern("I have ({string})", parameters)
    Condition
      Error:
      ! This Cucumber Expression has a problem at column 9:
      
      I have ({string})
              ^------^
      An optional may not contain a parameter type.
      If you did not mean to use an parameter type you can use '\{' to escape the '{'
      In an R string, double each backslash: "\\{".

---

    Code
      expression_to_pattern("I have ()", parameters)
    Condition
      Error:
      ! This Cucumber Expression has a problem at column 8:
      
      I have ()
             ^^
      An optional must contain some text.
      If you did not mean to use an optional you can use '\(' to escape the '('
      In an R string, double each backslash: "\\(".

---

    Code
      expression_to_pattern("I visit /about", parameters)
    Condition
      Error:
      ! This Cucumber Expression has a problem at column 9:
      
      I visit /about
              ^
      Alternative may not be empty.
      If you did not mean to use an alternative you can use '\/' to escape the '/'
      In an R string, double each backslash: "\\/".

---

    Code
      expression_to_pattern("a//b", parameters)
    Condition
      Error:
      ! This Cucumber Expression has a problem at column 3:
      
      a//b
        ^
      Alternative may not be empty.
      If you did not mean to use an alternative you can use '\/' to escape the '/'
      In an R string, double each backslash: "\\/".

---

    Code
      expression_to_pattern("{string}/{string}", parameters)
    Condition
      Error:
      ! This Cucumber Expression has a problem at column 9:
      
      {string}/{string}
              ^
      Alternative may not be empty.
      If you did not mean to use an alternative you can use '\/' to escape the '/'
      In an R string, double each backslash: "\\/".

---

    Code
      expression_to_pattern("I have (a/b)", parameters)
    Condition
      Error:
      ! This Cucumber Expression has a problem at column 10:
      
      I have (a/b)
               ^
      An alternation can not be used inside an optional.
      If you did not mean to use an alternation you can use '\/' to escape the '/'. Otherwise rephrase your expression or consider using a regular expression instead.
      In an R string, double each backslash: "\\/".

---

    Code
      expression_to_pattern("I have (a)/b", parameters)
    Condition
      Error:
      ! This Cucumber Expression has a problem at column 8:
      
      I have (a)/b
             ^-^
      An alternative may not exclusively contain optionals.
      If you did not mean to use an optional you can use '\(' to escape the '('
      In an R string, double each backslash: "\\(".

---

    Code
      expression_to_pattern("I have {string", parameters)
    Condition
      Error:
      ! This Cucumber Expression has a problem at column 8:
      
      I have {string
             ^
      The '{' does not have a matching '}'.
      If you did not intend to use a parameter you can use '\{' to escape the a parameter
      In an R string, double each backslash: "\\{".

---

    Code
      expression_to_pattern("I have (s", parameters)
    Condition
      Error:
      ! This Cucumber Expression has a problem at column 8:
      
      I have (s
             ^
      The '(' does not have a matching ')'.
      If you did not intend to use optional text you can use '\(' to escape the optional text
      In an R string, double each backslash: "\\(".

---

    Code
      expression_to_pattern("I have {a(b}", parameters)
    Condition
      Error:
      ! This Cucumber Expression has a problem at column 10:
      
      I have {a(b}
               ^
      Parameter names may not contain '{', '}', '(', ')', '\' or '/'.
      Did you mean to use a regular expression?

---

    Code
      expression_to_pattern("I have \\a", parameters)
    Condition
      Error:
      ! This Cucumber Expression has a problem at column 9:
      
      I have \a
              ^
      Only the characters '{', '}', '(', ')', '\', '/' and whitespace can be escaped.
      If you did mean to use an '\' you can use '\\' to escape it
      In an R string, double each backslash: "\\\\".

---

    Code
      expression_to_pattern("I have \\", parameters)
    Condition
      Error:
      ! This Cucumber Expression has a problem at column 8:
      
      I have \
             ^
      The end of line can not be escaped.
      You can use '\\' to escape the '\'
      In an R string, double each backslash: "\\\\".

# expression_to_pattern / should fail when a capture group's regexp is the regexp of several parameter types

    Code
      expression_to_pattern("^(\\d+)$", parameters)
    Condition
      Error:
      ! Your Regular Expression ^(\d+)$
      matches multiple parameter types with regexp \d+:
         {a}
         {b}
      
      I couldn't decide which one to use. Use a Cucumber Expression instead of a Regular Expression, or make one of the parameter types preferential with `prefer_for_regexp_match = TRUE`.

