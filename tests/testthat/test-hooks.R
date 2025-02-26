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

  it("should register one hook", {
    withr::with_options(list(.cucumber_hooks = .hooks()), {
      # Arrange
      hook <- function(context, scenario) {
      }
      before(hook)

      # Act
      h <- get_hook(name = "before")

      # Assert
      expect_equal(h, hook)
    })
  })

  it("should register both hooks", {
    withr::with_options(list(.cucumber_hooks = .hooks()), {
      # Arrange
      hook1 <- function(context, scenario) {
      }
      hook2 <- function(context, scenario) {
      }

      # Act
      before(hook1)
      after(hook2)

      # Assert
      expect_equal(get_hook(name = "before"), hook1)
      expect_equal(get_hook(name = "after"), hook2)
    })
  })
})
