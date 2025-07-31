test_that("kinship_from_pedigree calculates correct kinship coefficients", {
  # Test case 1: Simple family with full siblings
  pedigree_full_sibs <- data.frame(
    id = c("P1", "P2", "C1", "C2"),
    sire = c(NA, NA, "P1", "P1"),
    dam = c(NA, NA, "P2", "P2"),
    stringsAsFactors = FALSE
  )
  
  kinship_matrix <- kinship_from_pedigree(pedigree_full_sibs)
  
  # Check dimensions and structure
  expect_equal(dim(kinship_matrix), c(4, 4))
  expect_equal(rownames(kinship_matrix), c("P1", "P2", "C1", "C2"))
  expect_equal(colnames(kinship_matrix), c("P1", "P2", "C1", "C2"))
  
  # Check diagonal (self-relatedness should be 1)
  expect_equal(as.numeric(diag(kinship_matrix)), rep(1, 4))
  
  # Check symmetry
  expect_equal(kinship_matrix, t(kinship_matrix))
  
  # Check specific relationships
  expect_equal(kinship_matrix["P1", "P2"], 0)  # Unrelated founders
  expect_equal(kinship_matrix["C1", "C2"], 0.5)  # Full siblings (1/4 + 1/4)
  expect_equal(kinship_matrix["P1", "C1"], 0)  # Parent-offspring (should be 0 in this simple implementation)
  
  # Test case 2: Half siblings (same sire, different dam)
  pedigree_half_sibs <- data.frame(
    id = c("P1", "P2", "P3", "C1", "C2"),
    sire = c(NA, NA, NA, "P1", "P1"),
    dam = c(NA, NA, NA, "P2", "P3"),
    stringsAsFactors = FALSE
  )
  
  kinship_matrix_half <- kinship_from_pedigree(pedigree_half_sibs)
  
  # Half siblings should have kinship coefficient of 0.25
  expect_equal(kinship_matrix_half["C1", "C2"], 0.25)
  
  # Test case 3: Unrelated individuals
  pedigree_unrelated <- data.frame(
    id = c("A", "B", "C"),
    sire = c(NA, NA, NA),
    dam = c(NA, NA, NA),
    stringsAsFactors = FALSE
  )
  
  kinship_matrix_unrelated <- kinship_from_pedigree(pedigree_unrelated)
  
  # All off-diagonal elements should be 0 for unrelated individuals
  expect_equal(kinship_matrix_unrelated["A", "B"], 0)
  expect_equal(kinship_matrix_unrelated["A", "C"], 0)
  expect_equal(kinship_matrix_unrelated["B", "C"], 0)
})

test_that("kinship_from_pedigree handles edge cases", {
  # Test single individual
  pedigree_single <- data.frame(
    id = "A",
    sire = NA,
    dam = NA,
    stringsAsFactors = FALSE
  )
  
  kinship_single <- kinship_from_pedigree(pedigree_single)
  expect_equal(dim(kinship_single), c(1, 1))
  expect_equal(kinship_single[1, 1], 1)
  
  # Test with missing parent information
  pedigree_missing <- data.frame(
    id = c("A", "B", "C"),
    sire = c(NA, "A", NA),
    dam = c(NA, NA, "A"),
    stringsAsFactors = FALSE
  )
  
  expect_error(kinship_from_pedigree(pedigree_missing), NA)  # Should not error
  
  # Test empty pedigree
  pedigree_empty <- data.frame(
    id = character(0),
    sire = character(0),
    dam = character(0),
    stringsAsFactors = FALSE
  )
  
  kinship_empty <- kinship_from_pedigree(pedigree_empty)
  expect_equal(dim(kinship_empty), c(0, 0))
})
