describe("hooks", {
  it("should throw an error if a hook doesn't have 2 arguments", {
    # Arrange
    hook <- function() {}

    # Act & Assert
    expect_error(
      make_hook("before")(hook),
      regexp = "Hook must have two arguments."
    )
  })

  it("should throw an error if a hook has already been registered", {
    withr::with_options(list(.cucumber_hooks = .hooks()), {
      # Arrange
      hook <- function(context, scenario) {}
      before(hook)

      # Act & Assert
      expect_error(
        before(hook),
        regexp = "Hook 'before' already registered."
      )
    })
  })

  it("should register a hook", {
    withr::with_options(list(.cucumber_hooks = .hooks()), {
      # Arrange
      hook <- function(context, scenario) {}
      before(hook)

      # Act
      h <- get_hook(name = "before")

      # Assert
      expect_equal(h, hook)
    })
  })
})
