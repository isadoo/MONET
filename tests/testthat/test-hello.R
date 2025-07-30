test_that("hello function works", {
  # Capture output
  output <- capture.output(hello())
  
  # Check that output contains the expected message
  expect_match(output, "Hello, world!")
})