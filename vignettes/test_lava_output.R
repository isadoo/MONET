# Script to test LAVA output with vignette example data
# This will help update the vignette with the current output format

library(LAVA)

# Load the example data from inst/extdata
cat("Loading example data from inst/extdata...\n")

# Load trait data
trait_df_pop <- read.csv(
  system.file("extdata", "vignette_trait_df_pop.csv", package = "LAVA")
)

cat("Trait data loaded:", nrow(trait_df_pop), "individuals\n")
head(trait_df_pop)

# Load population-individual mapping
population_individual_id_df <- read.csv(
  system.file("extdata", "vignette_population_individual_id_df.csv", package = "LAVA")
)

cat("\nPopulation-individual mapping loaded\n")
head(population_individual_id_df)

# Load F1 neutral dosages
dos_F1only_neutral <- readRDS(
  system.file("extdata", "vignette_dos_F1only_neutral.rds", package = "LAVA")
)

cat("\nF1 neutral dosages loaded:", dim(dos_F1only_neutral), "\n")

# Load parent neutral data using hierfstat
cat("\nLoading parent neutral data...\n")
neutral_file <- system.file("extdata", "neutral_data_g3000.dat", package = "LAVA")

if (file.exists(neutral_file)) {
  sim <- hierfstat::read.fstat(fname = neutral_file)
  dos <- hierfstat::biall2dos(sim[, -1])
  pop <- sim$Pop
  
  cat("Parent data loaded:", nrow(dos), "individuals,", ncol(dos), "loci\n")
  
  # Calculate coancestries
  cat("\nCalculating coancestries...\n")
  coancestries_dosage <- calculate_coancestries(
    genetic_data_parents = dos,
    genotyped_parent_populations = pop,
    genetic_data_F1 = dos_F1only_neutral, 
    population_individual_id = population_individual_id_df,
    column_individual = "individual", 
    column_population = "pop_id",
    all_parents_genotyped = TRUE
  )
  
  Theta.P <- coancestries_dosage$Theta.P
  M <- coancestries_dosage$M
  
  cat("Coancestries calculated successfully\n")
  cat("Theta.P dimensions:", dim(Theta.P), "\n")
  cat("M dimensions:", dim(M), "\n")
  
} else {
  cat("Warning: neutral_data_g3000.dat not found in inst/extdata\n")
  cat("Using placeholder data - you may need to add this file\n")
  # Create dummy data for testing
  Theta.P <- matrix(0.1, nrow = 18, ncol = 18)
  diag(Theta.P) <- 1
  M <- diag(nrow(trait_df_pop))
}

# Run LAVA
cat("\n" , rep("=", 60), "\n", sep = "")
cat("Running LAVA analysis...\n")
cat(rep("=", 60), "\n\n", sep = "")

results <- lava(
  Theta.P = Theta.P, 
  M = M, 
  trait_dataframe = trait_df_pop, 
  column_individual = "individual", 
  column_trait = "trait",
  save_full_model = FALSE
)

# Print results
cat("\n" , rep("=", 60), "\n", sep = "")
cat("LAVA RESULTS\n")
cat(rep("=", 60), "\n\n", sep = "")

print(results)

cat("\n\nDetailed output structure:\n")
cat(rep("-", 60), "\n", sep = "")
str(results, max.level = 2)

# Save results for reference
saveRDS(results, "vignettes/example_lava_results.rds")
cat("\n\nResults saved to: vignettes/example_lava_results.rds\n")

# Plot posterior
cat("\nGenerating posterior plot...\n")
pdf("vignettes/lava_posterior_plot.pdf", width = 8, height = 6)
plot(results)
dev.off()
cat("Plot saved to: vignettes/lava_posterior_plot.pdf\n")
