test_that("hello function works", {
  # Capture output
  output <- capture.output(hello())
  
  # Check that output matches expected value
  expect_equal(output, "\"Hello, world!\"")
})