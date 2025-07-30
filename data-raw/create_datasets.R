# Script to create and document datasets for the LAVA package

# Generate example data for the package
set.seed(123)

# Create a simple example dataset for demonstration
n_samples <- 100
populations <- c("Pop1", "Pop2", "Pop3")
ancestral_groups <- c("GroupA", "GroupB")

example_data <- data.frame(
  sample_id = paste0("Sample_", 1:n_samples),
  population = sample(populations, n_samples, replace = TRUE),
  variance = runif(n_samples, 0.5, 2.5),
  ancestral_group = sample(ancestral_groups, n_samples, replace = TRUE)
)

# Save the data in the package
usethis::use_data(example_data, overwrite = TRUE)

# Print confirmation
cat("Dataset 'example_data' created and saved to data/example_data.rda\n")