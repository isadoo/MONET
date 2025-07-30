test_that("is_numeric_vector works correctly", {
  expect_true(is_numeric_vector(1:10))
  expect_true(is_numeric_vector(c(1.5, 2.5, 3.5)))
  expect_false(is_numeric_vector("test"))
  expect_false(is_numeric_vector(list(1, 2, 3)))
  expect_false(is_numeric_vector(matrix(1:4, nrow = 2)))
})

test_that("is_positive_numeric works correctly", {
  expect_true(is_positive_numeric(1:10))
  expect_true(is_positive_numeric(c(1.5, 2.5, 3.5)))
  expect_false(is_positive_numeric(c(-1, 2, 3)))
  expect_false(is_positive_numeric(0))
  expect_false(is_positive_numeric("test"))
})