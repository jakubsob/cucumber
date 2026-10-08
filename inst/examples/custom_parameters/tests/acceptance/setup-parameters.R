define_parameter_type(
  name = "color",
  regexp = "red|blue|green",
  transformer = as.character
)

define_parameter_type(
  name = "sci_number",
  regexp = "[+-]?\\d*\\.?\\d+(?:e[+-]?\\d+)?",
  transformer = as.double
)
