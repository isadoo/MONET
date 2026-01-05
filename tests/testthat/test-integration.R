test_that("Package integration workflow works", {
  skip_if_not_installed("hierfstat")
  skip_if_not_installed("brms")
  skip("Integration test skipped - requires MCMC computation")
  
  # This test demonstrates the full workflow but is skipped due to computation time
  # In practice, you might run this manually or in a separate testing environment
  
  # # Step 1: Create synthetic genetic data
  # set.seed(12345)
  # n_parents <- 40
  # n_f1 <- 40
  # n_markers <- 100
  # n_populations <- 2
  # 
  # parent_dosage <- matrix(
  #   sample(0:2, n_parents * n_markers, replace = TRUE, prob = c(0.5, 0.3, 0.2)),
  #   nrow = n_parents, ncol = n_markers
  # )
  # 
  # f1_dosage <- matrix(
  #   sample(0:2, n_f1 * n_markers, replace = TRUE, prob = c(0.4, 0.4, 0.2)),
  #   nrow = n_f1, ncol = n_markers
  # )
  # 
  # # Step 2: Calculate coancestries
  # coancestries <- calculate_coancestries(
  #   genetic_data_parents = parent_dosage,
  #   genetic_data_F1 = f1_dosage,
  #   datatype = "dosage",
  #   number_of_populations = n_populations
  # )
  # 
  # # Step 3: Create trait data
  # trait_data <- data.frame(
  #   id = paste0("ind_", 1:n_f1),
  #   trait = rnorm(n_f1, mean = 0, sd = 1)
  # )
  # 
  # # Step 4: Run LAVA analysis
  # lava_result <- lava(
  #   Theta.P = coancestries$Theta.P,
  #   M = coancestries$M,
  #   trait_dataframe = trait_data,
  #   chains = 2, iter = 500, warmup = 250  # Minimal for testing
  # )
  # 
  # # Check that workflow completed successfully
  # expect_s3_class(lava_result, "lava")
  # expect_true("log_ratio" %in% names(lava_result))
  # 
  # # Test print and plot methods
  # expect_output(print(lava_result), "Log Ancestral Variance Analysis")
  # expect_error(plot(lava_result), NA)
})

test_that("Package handles edge cases gracefully", {
  # Test very small datasets - expect these to fail gracefully
  small_matrix <- matrix(1, 1, 1)
  small_trait <- data.frame(id = "ind1", trait = 1.0)
  
  # Should handle single individual case - expect specific error
  expect_error(
    lava(Theta.P = small_matrix, M = small_matrix, trait_dataframe = small_trait),
    "All observations in the data were removed|presumably because of NA values"
  )
  
  # Test identical individuals (no variance) - expect this to fail with brms error
  identical_trait <- data.frame(
    id = paste0("ind_", 1:4),
    trait = rep(1.0, 4)  # No variance
  )
  M <- diag(4)
  Theta.P <- matrix(0.1, 2, 2)
  diag(Theta.P) <- 0.2
  
  # This will cause issues in Bayesian modeling - expect error
  expect_error(
    lava(Theta.P = Theta.P, M = M, trait_dataframe = identical_trait),
    "All observations in the data were removed|presumably because of NA values"
  )
})

test_that("Utility functions handle boundary conditions", {
  # Test counting_blocks_matrix with extreme cases
  
  # All zeros matrix
  zero_matrix <- matrix(0, 3, 3)
  result_zero <- counting_blocks_matrix(zero_matrix)
  expect_s3_class(result_zero, "data.frame")
  
  # Single non-zero element
  sparse_matrix <- matrix(0, 3, 3)
  sparse_matrix[2, 2] <- 1
  result_sparse <- counting_blocks_matrix(sparse_matrix)
  expect_s3_class(result_sparse, "data.frame")
  expect_equal(nrow(result_sparse), 1)
  
  # Test kinship_from_pedigree with complex relationships
  complex_pedigree <- data.frame(
    id = c("F1", "F2", "F3", "F4", "O1", "O2", "O3", "O4"),
    sire = c(NA, NA, NA, NA, "F1", "F1", "F2", "F3"),
    dam = c(NA, NA, NA, NA, "F2", "F3", "F4", "F4"),
    stringsAsFactors = FALSE
  )
  
  kinship_complex <- kinship_from_pedigree(complex_pedigree)
  
  # Should be symmetric
  expect_equal(kinship_complex, t(kinship_complex))
  
  # Diagonal should be 1
  expect_equal(as.numeric(diag(kinship_complex)), rep(1, 8))
  
  # Should have appropriate kinship values
  expect_true(all(kinship_complex >= 0))
  expect_true(all(kinship_complex <= 1))
})

test_that("Data type conversions work correctly", {
  skip_if_not_installed("hierfstat")
  
  # Test that the package can handle different matrix types
  dense_matrix <- matrix(runif(16), 4, 4)
  sparse_like <- dense_matrix
  sparse_like[sparse_like < 0.5] <- 0
  
  # Both should work with counting_blocks_matrix
  expect_error(counting_blocks_matrix(dense_matrix), NA)
  expect_error(counting_blocks_matrix(sparse_like), NA)
  
  # Test data frame to matrix conversions in kinship function
  pedigree_df <- data.frame(
    id = c("A", "B", "C"),
    sire = c(NA, "A", "A"),
    dam = c(NA, NA, "B")
  )
  
  kinship_result <- kinship_from_pedigree(pedigree_df)
  expect_true(is.matrix(kinship_result))
  expect_equal(class(kinship_result), c("matrix", "array"))
})

test_that("Error messages are informative", {
  # Test that error messages guide users appropriately
  
  # Wrong data types
  expect_error(
    lava(Theta.P = list(1, 2), M = matrix(1, 2, 2), trait_dataframe = data.frame(id = 1:2, trait = 1:2)),
    "matrices"
  )
  
  # Insufficient trait data
  expect_error(
    lava(Theta.P = matrix(1, 2, 2), M = matrix(1, 2, 2), trait_dataframe = data.frame(single_col = 1:2)),
    "at least two columns"
  )
  
  # Invalid function in calculate_coancestries
  expect_error(
    calculate_coancestries(
      genetic_data_parents = matrix(1, 2, 2),
      genotyped_parent_populations = c(1, 1)
    ),
    "Missing F1 data"
  )
})
