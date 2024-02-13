describe("make_step", {
  it("should assert that step implementation has a context argument", {
    # Arrange
    implementation <- function() {

    }

    # Act, Assert
    expect_error(
      make_step("Given")("the Maker has the word '{string}'", implementation),
      regexp = "context",
      fixed = TRUE
    )
  })
})
