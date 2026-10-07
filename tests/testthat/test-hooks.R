describe("hooks", {
  it("should throw an error if a hook doesn't have 2 arguments", {
    # Arrange
    hook <- function() {}

    # Act & Assert
    expect_error(
      before(hook),
      regexp = "A `before` hook must have 2 arguments."
    )
  })

  it("should throw an error if a before_all hook has arguments", {
    expect_error(
      before_all(function(context) {}),
      regexp = "A `before_all` hook must have 0 arguments."
    )
  })

  it("should throw an error for an invalid tag expression", {
    withr::with_options(list(.cucumber_hooks = .hooks()), {
      expect_error(before(function(context, scenario) {}, tags = "@a and"))
    })
  })

  it("should register many hooks of one kind", {
    withr::with_options(list(.cucumber_hooks = .hooks()), {
      # Arrange
      hook1 <- function(context, scenario) {}
      hook2 <- function(context, scenario) {}

      # Act
      before(hook1)
      before(hook2)

      # Assert
      expect_equal(get_hooks_to_run(get_hooks(), "before"), list(hook1, hook2))
    })
  })

  it("should run after hooks in the reverse order", {
    withr::with_options(list(.cucumber_hooks = .hooks()), {
      # Arrange
      hook1 <- function(context, scenario) {}
      hook2 <- function(context, scenario) {}

      # Act
      after(hook1)
      after(hook2)

      # Assert
      expect_equal(get_hooks_to_run(get_hooks(), "after"), list(hook2, hook1))
    })
  })

  it("should select hooks by tags", {
    withr::with_options(list(.cucumber_hooks = .hooks()), {
      # Arrange
      hook1 <- function(context, scenario) {}
      hook2 <- function(context, scenario) {}

      # Act
      before(hook1, tags = "@db")
      before(hook2)

      # Assert
      expect_equal(get_hooks_to_run(get_hooks(), "before", "db"), list(hook1, hook2))
      expect_equal(get_hooks_to_run(get_hooks(), "before", "ui"), list(hook2))
    })
  })
})
