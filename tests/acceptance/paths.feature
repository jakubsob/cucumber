Feature: Choosing feature files
  `test(path)` runs every `.feature` file in `path`, searched recursively.
  Run only some of them by listing them in `features`, or with a `filter` on their file names.

  Background:
    Given a package
    And a file named "features/addition.feature" with
      """
      Feature: Addition
        Scenario: Adding
          Given I have 1
          Then I get 1
      """
    And a file named "features/math/subtraction.feature" with
      """
      Feature: Subtraction
        Scenario: Subtracting
          Given I have 2
          Then I get 2
      """
    And a file named "features/math/advanced/division.feature" with
      """
      Feature: Division
        Scenario: Dividing
          Given I have 3
          Then I get 3
      """
    And a file named "features/setup-steps.R" with
      """
      given("I have {int}", function(n, context) {
        context$value <- n
      })
      then("I get {int}", function(n, context) {
        expect_equal(context$value, n)
      })
      """

  @rd
  Scenario: Feature files in the directory and its subdirectories are run
    When I run
      """
      test("features")
      """
    Then only these scenarios ran:
      | scenario    |
      | Adding      |
      | Subtracting |
      | Dividing    |

  Scenario: A symbolic link to a feature file is run
    Given a file named "elsewhere/multiplication.feature" with
      """
      Feature: Multiplication
        Scenario: Multiplying
          Given I have 4
          Then I get 4
      """
    When I run
      """
      fs::link_create(fs::path_abs("elsewhere/multiplication.feature"), "features/multiplication.feature")
      test("features")
      """
    Then only these scenarios ran:
      | scenario    |
      | Adding      |
      | Subtracting |
      | Dividing    |
      | Multiplying |

  Rule: `features` lists the feature files to run

    @rd
    Scenario: Only the listed feature files are run
      When I run
        """
        test("features", features = c("addition.feature", "math/subtraction.feature"))
        """
      Then only these scenarios ran:
        | scenario    |
        | Adding      |
        | Subtracting |

    Scenario: The listed feature files run in the order they are listed
      When I run
        """
        test("features", features = c("math/subtraction.feature", "addition.feature"))
        """
      Then these scenarios ran in this order:
        | scenario    |
        | Subtracting |
        | Adding      |

    Scenario: A feature file that doesn't exist is an error
      When I run
        """
        test("features", features = "multiplication.feature", stop_on_failure = FALSE)
        """
      Then the error message includes "Feature files not found."
      And the error message includes "multiplication.feature"

  Rule: `filter` runs the feature files whose name matches a regular expression

    The name is the file name without `.feature`. Extra arguments of `test()` are passed to `grepl()`.

    @rd
    Scenario: Only feature files whose name matches are run
      When I run
        """
        test("features", filter = "^(addition|division)$")
        """
      Then only these scenarios ran:
        | scenario |
        | Adding   |
        | Dividing |

    Scenario: Arguments of grepl() change how the name is matched
      When I run
        """
        test("features", filter = "ADDITION", ignore.case = TRUE)
        """
      Then only these scenarios ran:
        | scenario |
        | Adding   |

    Scenario: An argument that isn't an argument of test() or grepl() is an error
      When I run it and it fails
        """
        test("features", fail_fst = TRUE)
        """
      Then it fails with
        """
        Unknown argument: `fail_fst`.
        i Arguments of `grepl()` for `filter` can be passed in `...`: `ignore.case`, `perl`, `fixed`, `useBytes`.
        """
