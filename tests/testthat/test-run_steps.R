describe("step", {
  it("should run the matching step", {
    feature <- structure(
      c(
        "Feature: Add",
        "  Scenario: Adding 1 + 1",
        "    Given I have numbers '1' and '1'",
        "    When I add numbers '1' and '1'",
        "    Then the result is '2'"
      ),
      context = new.env()
    )

    given("Given I have numbers {int} and {int}", function(num_1, num_2, context) {

    }, .feature = feature)

    when("When I add numbers {int} and {int}", function(num_1, num_2, context) {
      context$result <- num_1 + num_2
    }, .feature = feature)

    then("Then the result is {int}", function(result, context) {
      expect_equal(context$result, 2)
    }, .feature = feature)
  })
})
