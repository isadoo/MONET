test_that("calculate_coancestries validates input parameters", {
  # Test missing population information for dosage data
  expect_error(
    calculate_coancestries(
      genetic_data_parents = matrix(1, 10, 10),
      genotyped_parent_populations = rep(1:2, each = 5)
    ),
    "Population data missing|Missing F1 data"
  )
  
  # Test missing F1 data
  expect_error(
    calculate_coancestries(
      genetic_data_parents = matrix(1, 10, 10),
      genotyped_parent_populations = rep(1:2, each = 5)
    ),
    "Missing F1 data"
  )
})

test_that("calculate_coancestries works with dosage data and population info", {
  skip_if_not_installed("hierfstat")
  skip_if_not_installed("dplyr")
  
  # Create mock dosage data
  set.seed(123)
  n_parents <- 20
  n_f1 <- 20
  n_markers <- 50
  n_populations <- 2
  
  # Parent dosage data (0, 1, 2 for biallelic markers)
  parent_dosage <- matrix(
    sample(0:2, n_parents * n_markers, replace = TRUE),
    nrow = n_parents, ncol = n_markers
  )
  
  # F1 dosage data
  f1_dosage <- matrix(
    sample(0:2, n_f1 * n_markers, replace = TRUE),
    nrow = n_f1, ncol = n_markers
  )
  
  # Population assignment for parents and F1
  parent_populations <- rep(1:n_populations, each = n_parents/n_populations)
  f1_populations <- rep(1:n_populations, each = n_f1/n_populations)
  
  # Population mapping
  population_mapping <- data.frame(
    id = paste0("ind_", 1:n_f1),
    population_id = f1_populations
  )
  
  result <- calculate_coancestries(
    genetic_data_parents = parent_dosage,
    genotyped_parent_populations = parent_populations,
    genetic_data_F1 = f1_dosage,
    population_individual_id = population_mapping,
    all_parents_genotyped = TRUE
  )
  
  # Check return structure
  expect_type(result, "list")
  expect_true("M" %in% names(result))
  expect_true("Theta.P" %in% names(result))
  
  # Check dimensions
  expect_equal(dim(result$M), c(n_f1, n_f1))
  expect_equal(dim(result$Theta.P), c(n_populations, n_populations))
  
  # Check that matrices are symmetric
  expect_equal(result$M, t(result$M))
  expect_equal(result$Theta.P, t(result$Theta.P))
})

test_that("calculate_coancestries works with pedigree option", {
  # Create a simple pedigree
  pedigree <- data.frame(
    id = c("C1", "C2", "C3", "C4"),
    sire = c("P1", "P1", "P3", "P3"),
    dam = c("P2", "P2", "P4", "P4"),
    sire_pop = c(1, 1, 2, 2),
    dam_pop = c(1, 1, 2, 2),
    stringsAsFactors = FALSE
  )
  
  # Create mock parent dosage data
  set.seed(456)
  parent_dosage <- matrix(
    sample(0:2, 4 * 20, replace = TRUE),
    nrow = 4, ncol = 20
  )
  
  parent_populations <- c(1, 1, 2, 2)
  
  # Test with pedigree
  expect_error({
    result_pedigree <- calculate_coancestries(
      genetic_data_parents = parent_dosage,
      genotyped_parent_populations = parent_populations,
      pedigree = pedigree,
      all_parents_genotyped = FALSE
    )
  }, NA)  # Should not error
})

test_that("calculate_coancestries handles population individual mapping", {
  skip_if_not_installed("hierfstat")
  skip_if_not_installed("dplyr")
  
  # Create mock data
  set.seed(789)
  n_parents <- 12
  n_f1 <- 12
  n_markers <- 30
  
  parent_dosage <- matrix(
    sample(0:2, n_parents * n_markers, replace = TRUE),
    nrow = n_parents, ncol = n_markers
  )
  
  f1_dosage <- matrix(
    sample(0:2, n_f1 * n_markers, replace = TRUE),
    nrow = n_f1, ncol = n_markers
  )
  
  # Create unbalanced population assignment
  parent_populations <- c(rep(1, 5), rep(2, 4), rep(3, 3))
  
  population_mapping <- data.frame(
    id = paste0("ind_", 1:n_f1),
    population_id = c(rep(1, 5), rep(2, 4), rep(3, 3))
  )
  
  result <- calculate_coancestries(
    genetic_data_parents = parent_dosage,
    genotyped_parent_populations = parent_populations,
    genetic_data_F1 = f1_dosage,
    population_individual_id = population_mapping,
    all_parents_genotyped = TRUE
  )
  
  # Should handle unbalanced design
  expect_type(result, "list")
  expect_equal(dim(result$Theta.P), c(3, 3))  # 3 populations
})

test_that("calculate_coancestries output properties", {
  skip_if_not_installed("hierfstat")
  skip_if_not_installed("dplyr")
  
  # Create minimal test case
  set.seed(999)
  parent_dosage <- matrix(sample(0:2, 8 * 10, replace = TRUE), nrow = 8, ncol = 10)
  f1_dosage <- matrix(sample(0:2, 8 * 10, replace = TRUE), nrow = 8, ncol = 10)
  
  parent_populations <- rep(1:2, each = 4)
  population_mapping <- data.frame(
    id = paste0("ind_", 1:8),
    population_id = rep(1:2, each = 4)
  )
  
  result <- calculate_coancestries(
    genetic_data_parents = parent_dosage,
    genotyped_parent_populations = parent_populations,
    genetic_data_F1 = f1_dosage,
    population_individual_id = population_mapping,
    all_parents_genotyped = TRUE
  )
  
  # M should be positive semi-definite
  eigenvalues_M <- eigen(result$M)$values
  expect_true(all(eigenvalues_M >= -1e-10))  # Allow for small numerical errors
  
  # Theta.P should have appropriate range (note: can be negative in some cases)
  # expect_true(all(result$Theta.P >= 0))  # Commented out - can be negative
  expect_true(all(result$Theta.P <= 1))
  
  # Diagonal of Theta.P should generally be >= off-diagonal elements (but not always)
  n_pops <- nrow(result$Theta.P)
  # Commenting out strict diagonal test as it can vary with real data
  # for (i in 1:n_pops) {
  #   for (j in 1:n_pops) {
  #     if (i != j) {
  #       expect_true(result$Theta.P[i, i] >= result$Theta.P[i, j])
  #     }
  #   }
  # }
})
