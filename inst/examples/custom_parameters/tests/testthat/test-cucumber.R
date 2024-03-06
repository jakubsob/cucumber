define_parameter_type(
  name = "color",
  regexp = "red|blue|green",
  transform = as.character
)

test(".", "./steps")
