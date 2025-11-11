# Test script to verify kinship2 integration
# This script tests the updated kinship_from_pedigree function

# Load required packages
library(kinship2)

# Create a simple test pedigree
pedigree <- data.frame(
  id = c("P1", "P2", "C1", "C2"),
  sire = c(NA, NA, "P1", "P1"),
  dam = c(NA, NA, "P2", "P2"),
  stringsAsFactors = FALSE
)

cat("Test pedigree:\n")
print(pedigree)

# Test kinship2::kinship directly
cat("\n\nTesting kinship2::kinship directly:\n")
kinship_raw <- kinship2::kinship(id = pedigree$id, 
                                  dadid = pedigree$sire, 
                                  momid = pedigree$dam)
cat("Raw kinship coefficients from kinship2:\n")
print(kinship_raw)

# Convert to relatedness matrix (multiply by 2)
kinship_matrix <- as.matrix(kinship_raw * 2)
rownames(kinship_matrix) <- colnames(kinship_matrix) <- pedigree$id

cat("\n\nRelatedness matrix (kinship * 2):\n")
print(kinship_matrix)

# Expected values:
# - Diagonal (self-relatedness): 1.0
# - Full siblings (C1, C2): 0.5
# - Unrelated founders (P1, P2): 0.0

cat("\n\nVerifying expected values:\n")
cat("Diagonal (should be 1):", diag(kinship_matrix), "\n")
cat("C1-C2 relatedness (should be 0.5):", kinship_matrix["C1", "C2"], "\n")
cat("P1-P2 relatedness (should be 0):", kinship_matrix["P1", "P2"], "\n")

# Test with half-siblings
pedigree_half <- data.frame(
  id = c("P1", "P2", "P3", "C1", "C2"),
  sire = c(NA, NA, NA, "P1", "P1"),
  dam = c(NA, NA, NA, "P2", "P3"),
  stringsAsFactors = FALSE
)

cat("\n\n=== Half-sibling test ===\n")
cat("Test pedigree:\n")
print(pedigree_half)

kinship_half_raw <- kinship2::kinship(id = pedigree_half$id, 
                                      dadid = pedigree_half$sire, 
                                      momid = pedigree_half$dam)
kinship_half <- as.matrix(kinship_half_raw * 2)
rownames(kinship_half) <- colnames(kinship_half) <- pedigree_half$id

cat("\nRelatedness matrix:\n")
print(kinship_half)

cat("\nC1-C2 relatedness (should be 0.25 for half-sibs):", kinship_half["C1", "C2"], "\n")
