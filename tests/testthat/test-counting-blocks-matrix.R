test_that("counting_blocks_matrix works correctly", {
  # Test case 1: Simple block matrix
  test_matrix_1 <- matrix(c(
    1, 1, 0, 0,
    1, 1, 0, 0,
    0, 0, 2, 2,
    0, 0, 2, 2
  ), nrow = 4, byrow = TRUE)
  
  result_1 <- counting_blocks_matrix(test_matrix_1)
  
  expect_s3_class(result_1, "data.frame")
  expect_equal(nrow(result_1), 2)  # Should have 2 blocks
  expect_equal(result_1$block, c(1, 2))
  expect_equal(result_1$rows, c(2, 2))
  expect_equal(result_1$cols, c(2, 2))
  
  # Test case 2: Single block matrix
  test_matrix_2 <- matrix(c(
    1, 1, 1,
    1, 1, 1,
    1, 1, 1
  ), nrow = 3, byrow = TRUE)
  
  result_2 <- counting_blocks_matrix(test_matrix_2)
  
  expect_equal(nrow(result_2), 1)  # Should have 1 block
  expect_equal(result_2$block, 1)
  expect_equal(result_2$rows, 3)
  expect_equal(result_2$cols, 3)
  
  # Test case 3: Identity matrix (each individual is its own block)
  test_matrix_3 <- diag(4)
  
  result_3 <- counting_blocks_matrix(test_matrix_3)
  
  expect_equal(nrow(result_3), 4)  # Should have 4 blocks
  expect_equal(result_3$rows, rep(1, 4))
  expect_equal(result_3$cols, rep(1, 4))
  
  # Test case 4: Matrix with zeros (no blocks)
  test_matrix_4 <- matrix(0, nrow = 3, ncol = 3)
  
  expect_error(counting_blocks_matrix(test_matrix_4), NA)  # Should not error but may give empty result
})

test_that("counting_blocks_matrix handles edge cases", {
  # Test single row matrix
  test_matrix_single <- matrix(c(1, 1, 0), nrow = 1)
  result_single <- counting_blocks_matrix(test_matrix_single)
  
  expect_s3_class(result_single, "data.frame")
  expect_equal(nrow(result_single), 1)
  
  # Test single column matrix
  test_matrix_col <- matrix(c(1, 1, 0), ncol = 1)
  result_col <- counting_blocks_matrix(test_matrix_col)
  
  expect_s3_class(result_col, "data.frame")
})
