describe("run", {
  it("should run the step implementation with parameters from docstring", {
    # Arrange
    context <- new.env()
    input <- "When I add numbers 1 and 1.1"
    step <- when("I add numbers {int} and {float}", \(num_1, num_2, context) {
      context$result <- num_1 + num_2
    })

    # Act
    run(step, input, context)

    # Assert
    expect_equal(context$result, 2.1)
  })
})
