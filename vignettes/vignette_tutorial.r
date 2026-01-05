# Script to generate example data for the LAVA package vignette tutorial
# This script creates all the data files that will be included in inst/extdata/
# and demonstrates the workflow that users will follow in the vignette

# Install/update LAVA package if needed
# devtools::install_github("isadoo/LAVA")  # Comment out to avoid overwriting local changes

library(LAVA)
library(hierfstat)
library(brms)


library(JGTeach)
library(gaston)
library(Matrix)

source("/users/ijeronim/mywork/Chapter2/Package/create_F1.r")

# Source the latest lava function with print method for testing
source("/users/ijeronim/mywork/LAVA/R/lava.r")

cat("================================================================\n")
cat("LAVA VIGNETTE DATA GENERATION AND TUTORIAL SCRIPT\n")
cat("================================================================\n\n")

# ============================================================
# PART 1: GENERATE EXAMPLE DATA (for package developers)
# ============================================================
cat("PART 1: Generating example data for package...\n")
cat("----------------------------------------------------------------\n\n")

# Load source data files
lava_extdata <- system.file("extdata", package = "LAVA")

neutral_file <- file.path(lava_extdata, "neutral_data_g3000.dat")
quanti_file <- file.path(lava_extdata, "quanti_trait_g3000.dat")

#read data
sim <- hierfstat::read.fstat(fname = neutral_file)
sim_quanti <- hierfstat::read.fstat(fname = quanti_file)

cat("Genetic data loaded:\n")
cat("  - Individuals:", nrow(sim), "\n")
cat("  - Neutral loci:", ncol(sim) - 1, "\n")
cat("  - Populations:", length(unique(sim$Pop)), "\n\n")

# Convert to dosage format
dos <- hierfstat::biall2dos(sim[, -1])
dos_quanti <- hierfstat::biall2dos(sim_quanti[, -1], diploid = TRUE)
pop <- sim$Pop

cat("Creating F1 generation \n")
# Breeding design: within-population crosses (5x5 sires x dams per population)
pop_sizes <- table(sim[, 1])
np <- length(pop_sizes)
offsrping_per_mating <- 2

sire <- c()
dam <- c()

for (i in 1:np) {
  n_ind <- pop_sizes[i]
  n_sire <- n_ind / 2
  n_dam <- n_ind / 2
  
  sire <- c(sire, rep((i - 1) * n_ind + 1:(n_sire), each = n_dam * offsrping_per_mating))
  dam <- c(dam, rep((i - 1) * n_ind + (n_sire + 1):n_ind, each = offsrping_per_mating, times = n_sire))
}

# Founders as NA
nft <- sum(pop_sizes)
sire <- c(rep(NA, nft), sire)
dam <- c(rep(NA, nft), dam)
nt <- length(sire)
nf <- -c(1:nft)  # non-founders

pedi <- data.frame(ind = 1:nt, sire = sire, dam = dam)
F1_full_data <- create_F1(sim, sim_quanti, pedi)

# Build F1 population structure
sire_per_pop <- as.vector(pop_sizes) / 2
dam_per_pop <- as.vector(pop_sizes) / 2
offspring_per_pop_F1 <- sire_per_pop * dam_per_pop * 2
pop_F1 <- rep(1:np, offspring_per_pop_F1)

cat("F1 generation created:\n")
cat("  - Total F1 individuals:", length(pop_F1), "\n")
cat("  - Individuals per population:", unique(offspring_per_pop_F1), "\n\n")

# Extract F1 data (excluding founders)
dos_F1only_neutral <- F1_full_data$dos_F1_neutral[nf, ]
dosage_quanti_F1 <- F1_full_data$dos_F1_quanti[nf, ]

# Create trait from QTLs
Y <- rowSums((dosage_quanti_F1 - 1) * 0.2)
err <- rnorm(length(Y), mean = 0, sd = 1)
Y <- Y + err
mean_Y <- mean(Y)
centered_Y <- Y - mean_Y
var_Y <- var(centered_Y)
trait <- centered_Y / sqrt(var_Y)

# Build data frames
NTraits <- 1
individual <- rep(1:(length(trait) / NTraits), NTraits)
population_individual_id_df <- data.frame(pop_id = pop_F1, individual = individual)
trait_id <- rep(1:NTraits, each = (length(trait) / NTraits))
population <- rep(pop_F1, NTraits)
trait_df_pop <- data.frame(individual, trait, trait_id, population)

# Save all data files to inst/extdata
save_path <- file.path("/users/ijeronim/mywork/LAVA/inst/extdata")


write.csv(population_individual_id_df, 
          file.path(save_path, "vignette_population_individual_id_df.csv"), 
          row.names = FALSE)
saveRDS(dos_F1only_neutral, 
        file.path(save_path, "vignette_dos_F1only_neutral.rds"))
saveRDS(dosage_quanti_F1, 
        file.path(save_path, "vignette_dosage_quanti_F1.rds"))
write.csv(trait_df_pop, 
          file.path(save_path, "vignette_trait_df_pop.csv"), 
          row.names = FALSE)

# ============================================================
# PART 2: VIGNETTE TUTORIAL WORKFLOW (what users will follow)
# ============================================================
cat("================================================================\n")
cat("PART 2: VIGNETTE TUTORIAL WORKFLOW\n")
cat("================================================================\n\n")
devtools::install_github("isadoo/LAVA")
#load lava
library(LAVA)

cat("Step 1: Getting the genetic data to dosages\n")
cat("------------------------------------------------------\n")

# Read data from package example files (as users will do)
neutral_file <- system.file("extdata", "neutral_data_g3000.dat", package = "LAVA")
quanti_file <- system.file("extdata", "quanti_trait_g3000.dat", package = "LAVA")

sim <- hierfstat::read.fstat(fname = neutral_file)
sim_quanti <- hierfstat::read.fstat(fname = quanti_file)

cat("First 5 rows, first 5 columns:\n")
print(sim[1:5, 1:5])
cat("\n")

dos <- hierfstat::biall2dos(sim[, -1])
dos_quanti <- hierfstat::biall2dos(sim_quanti[, -1], diploid = TRUE)
pop <- sim$Pop

cat("Dosage format - first 5 rows, first 5 loci:\n")
print(dos[1:5, 1:5])
cat("\n")

# Load F1 dosages
dos_F1only_neutral <- readRDS(
  system.file("extdata", "vignette_dos_F1only_neutral.rds", package = "LAVA")
)
cat("F1 neutral dosages loaded:", dim(dos_F1only_neutral), "\n\n")

cat("Step 2: Loading trait data and population identification\n")
cat("------------------------------------------------------\n")

trait_df_pop <- read.csv(
  system.file("extdata", "vignette_trait_df_pop.csv", package = "LAVA")
)

population_individual_id_df <- read.csv(
  system.file("extdata", "vignette_population_individual_id_df.csv", package = "LAVA")
)

cat("Trait data (first 6 rows):\n")
print(head(trait_df_pop))
cat("\n")

cat("Population-individual mapping (first 6 rows):\n")
print(head(population_individual_id_df))
cat("\n")

cat("Step 3: Calculating coancestries\n")
cat("------------------------------------------------------\n")

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

cat("Coancestry matrices calculated:\n")
cat("  Theta.P dimensions:", dim(Theta.P), "\n")
cat("  M dimensions:", dim(M), "\n\n")

# Save matrices for future use
saveRDS(Theta.P, file.path(save_path, "vignette_Theta_P.rds"))
saveRDS(M, file.path(save_path, "vignette_M.rds"))
cat("Matrices saved to inst/extdata\n\n")

cat("Step 4: Running lava()\n")
cat("------------------------------------------------------\n")

results <- lava(
  Theta.P = Theta.P,
  M = M,
  trait_dataframe = trait_df_pop,
  column_individual = "individual",
  column_trait = "trait",
  save_full_model = FALSE,
  iter = 4000,           
  warmup = 2000,         
  control = list(adapt_delta = 0.95, max_treedepth = 12)  
)

cat("\n")
cat("================================================================\n")
cat("LAVA RESULTS FOR VIGNETTE\n")
cat("================================================================\n\n")

print(results)



# Save results
saveRDS(results, file.path(save_path, "vignette_lava_results.rds"))
cat("Results saved to inst/extdata/vignette_lava_results.rds\n\n")

