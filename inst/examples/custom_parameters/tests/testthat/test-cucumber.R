define_parameter_type(
  name = "color",
  regexp = "red|blue|green",
  transform = as.character
)

define_parameter_type(
  name = "sci_number",
  regexp = "[+-]?\\\\d*\\\\.?\\\\d+(e[+-]?\\\\d+)?",
  transform = as.double
)

test(".", "./steps")
