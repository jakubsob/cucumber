when("a JPEG image is attached", function(context) {
  context$attach(readBin("cucumber.jpeg", "raw", file.size("cucumber.jpeg")), "image/jpeg")
})

when("a PNG image is attached", function(context) {
  context$attach(readBin("cucumber.png", "raw", file.size("cucumber.png")), "image/png")
})
