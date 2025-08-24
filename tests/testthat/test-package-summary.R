# Test Suite Summary for LAVA Package

# This file documents the comprehensive test suite for the LAVA package
# and provides examples of how the functions should be used.

test_that("Package documentation examples work correctly", {
  # Example 1: Basic kinship calculation from pedigree
  pedigree_example <- data.frame(
    id = c("P1", "P2", "C1", "C2"),
    sire = c(NA, NA, "P1", "P1"),
    dam = c(NA, NA, "P2", "P2"),
    stringsAsFactors = FALSE
  )
  
  kinship_result <- kinship_from_pedigree(pedigree_example)
  
  # Basic checks
  expect_true(is.matrix(kinship_result))
  expect_equal(nrow(kinship_result), 4)
  expect_equal(ncol(kinship_result), 4)
  
  # Example 2: Block counting for population structure
  block_matrix <- matrix(c(
    1, 1, 0, 0,
    1, 1, 0, 0,
    0, 0, 2, 2,
    0, 0, 2, 2
  ), nrow = 4, byrow = TRUE)
  
  blocks <- counting_blocks_matrix(block_matrix)
  expect_equal(nrow(blocks), 2)  # Two populations
  expect_equal(blocks$rows, c(2, 2))  # Two individuals per population
})

test_that("Package function signatures are correct", {
  # Test that all exported functions have the expected signatures
  
  # lava function
  expect_true(exists("lava"))
  lava_formals <- names(formals(lava))
  expected_lava_params <- c("Theta.P", "The.M", "trait_dataframe", 
                           "column_individual", "column_trait", "...")
  expect_true(all(expected_lava_params %in% lava_formals))
  
  # calculate_coancestries function  
  expect_true(exists("calculate_coancestries"))
  calc_formals <- names(formals(calculate_coancestries))
  expected_calc_params <- c("genetic_data_parents", "genotyped_parent_populations", 
                           "genetic_data_F1", "population_individual_id", 
                           "column_individual", "column_population", "pedigree", 
                           "all_parents_genotyped")
  expect_true(all(expected_calc_params %in% calc_formals))
  
  # kinship_from_pedigree function
  expect_true(exists("kinship_from_pedigree"))
  kinship_formals <- names(formals(kinship_from_pedigree))
  expect_true("pedigree" %in% kinship_formals)
  
  # counting_blocks_matrix function
  expect_true(exists("counting_blocks_matrix"))
  blocks_formals <- names(formals(counting_blocks_matrix))
  expect_true("mat" %in% blocks_formals)
})

test_that("S3 methods are properly registered", {
  # Check that print and plot methods exist for lava objects
  methods_print <- methods(print)
  methods_plot <- methods(plot)
  
  expect_true("print.lava" %in% methods_print)
  expect_true("plot.lava" %in% methods_plot)
})

test_that("Package dependencies are available", {
  # Check that required packages can be loaded
  skip_if_not_installed("brms")
  skip_if_not_installed("hierfstat")
  
  expect_true(requireNamespace("brms", quietly = TRUE))
  expect_true(requireNamespace("hierfstat", quietly = TRUE))
})

test_that("Package version and metadata", {
  # Basic package information tests
  package_info <- packageDescription("LAVA")
  
  expect_true(!is.na(package_info$Version))
  expect_true(!is.na(package_info$Title))
  expect_true(!is.na(package_info$Author))
  
  # Check that required imports are listed
  expect_true(grepl("brms", package_info$Imports))
  expect_true(grepl("hierfstat", package_info$Imports))
})
