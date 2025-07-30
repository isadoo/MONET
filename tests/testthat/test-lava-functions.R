test_that("calculate_lava returns correct values", {
  # Create test data with known variances
  x <- 1:10  # var = 9.166667
  y <- c(1, 3, 5, 7, 9)  # var = 11.5
  
  # Expected log ratio with natural log
  expected_ratio <- log(var(x) / var(y))
  
  # Test with default log base
  expect_equal(calculate_lava(x, y), expected_ratio)
  
  # Test with base 10
  expected_ratio_base10 <- log10(var(x) / var(y))
  expect_equal(calculate_lava(x, y, log_base = 10), expected_ratio_base10)
  
  # Test with base 2
  expected_ratio_base2 <- log2(var(x) / var(y))
  expect_equal(calculate_lava(x, y, log_base = 2), expected_ratio_base2)
})

test_that("calculate_lava validates inputs correctly", {
  x <- 1:10
  
  # Test non-numeric inputs
  expect_error(calculate_lava("not numeric", x))
  expect_error(calculate_lava(x, "not numeric"))
  expect_error(calculate_lava(list(1, 2, 3), x))
  expect_error(calculate_lava(x, list(1, 2, 3)))
})