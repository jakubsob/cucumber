describe("validate_feature", {
  it("should have only one 'Feature:' keyword", {
    expect_snapshot_error(
      validate_feature(
        c(
          "Feature: feature 1",
          "  Scenario: scenario",
          "Feature: bar"
        )
      )
    )
  })

  it("shouldn't produce error feature with valid indentation", {
    withr::with_options(list(cucumber.indent = "^\\s{2}"), {
      expect_no_error(
        validate_feature(
          c(
            "Feature: foo",
            "  Scenario: bar",
            "    Given foo",
            "    When foo",
            "    Then foo"
          )
        )
      )
    })
  })

  it("should validate indent", {
    withr::with_options(list(cucumber.indent = "^\\s{4}"), {
      expect_snapshot_error(
        validate_feature(
          c(
            "Feature: foo",
            "  Scenario: bar",
            "    Given foo",
            "    When foo",
            "    Then foo"
          )
        )
      )
    })
  })
})
