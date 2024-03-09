options(box.path = system.file("examples/box_support", package = "cucumber"))

box::use(
  cucumber,
)

cucumber$test(".", "./steps")
