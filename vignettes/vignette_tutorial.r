# Script to generate example data for the LAVA package vignette tutorial
# This script creates all the data files that will be included in inst/extdata/
# and demonstrates the workflow that users will follow in the vignette

# Load dependencies first (before loading LAVA package)
library(hierfstat)
library(brms)
library(gaston)
library(Matrix)

# Install JGTeach if needed (only needed for Part 1 - data generation)
if (!requireNamespace("JGTeach", quietly = TRUE)) {
  devtools::install_github("jgx65/JGTeach")
}
library(JGTeach)

# Now load LAVA package (this should not reload brms since it's already loaded)
devtools::load_all("/home/isa/github_repositories/LAVA")

source("/home/isa/github_repositories/LAVA/R/create_F1.r")


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
population <- rep(pop_F1, NTraits)
trait_df_pop <- data.frame(individual, trait, population)

# Save all data files to inst/extdata
save_path <- file.path("/home/isa/github_repositories/LAVA/inst/extdata")


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


saveRDS(Theta.P, file.path(save_path, "vignette_Theta_P.rds"))
saveRDS(M, file.path(save_path, "vignette_M.rds"))
saveRDS(pop_id, file.path(save_path, "vignette_pop_id.rds"))

#Environmental data
optima <- c(-2.3000000, -1.9196562, -1.2778076, -0.4392609, 0.4763456, 
            1.3636544, 2.1592261, 2.6803438, 2.9196562, 2.6803438, 
            2.1592261, 1.3636544, 0.4763456, -0.4392609, -1.2778076, 
            -1.9196562, -2.3000000, -2.2203438)

environment <- rep(optima, each = 50)
trait_df_pop_env <- cbind(trait_df_pop, environment = environment)
print(head(trait_df_pop_env))
write.csv(trait_df_pop_env, 
          file.path(save_path, "vignette_environment_df.csv"), 
          row.names = FALSE)

# ============================================================
# PART 2: VIGNETTE TUTORIAL WORKFLOW (what users will follow)
# ============================================================
cat("================================================================\n")
cat("PART 2: VIGNETTE TUTORIAL WORKFLOW\n")
cat("================================================================\n\n")

# Load LAVA (assumes package is already loaded from Part 1, or use library(LAVA) if installed)
cat("LAVA package loaded\n\n")

cat("Step 1: Load genetic data (dosage format)\n")
cat("------------------------------------------------------\n")

#Load parental dosages  ##########################
dos_P_neutral <- readRDS(
  system.file("extdata", "vignette_dos_parental_neutral.rds", package = "LAVA")
)

# Load F1 dosages ##########################
dos_F1only_neutral <- readRDS(
  system.file("extdata", "vignette_dos_F1only_neutral.rds", package = "LAVA")
)

###############################################

#Check files:

cat("Parental dosage format - first 5 individuals, first 5 loci:\n")
print(dos_P_neutral[1:5, 1:5])

cat("F1 dosage format - first 5 individuals, first 5 loci:\n")
print(dos_F1only_neutral[1:5, 1:5])
cat("\nF1 neutral dosages dimensions:", dim(dos_F1only_neutral), "\n\n")

cat("Step 2: Load trait data and visualize trait distribution\n")
cat("------------------------------------------------------\n")

trait_df_pop <- read.csv(
  system.file("extdata", "vignette_trait_df_pop.csv", package = "LAVA")
)

#Load population to individual identification dataframe (This is just the F1s)
population_individual_id <- read.csv(
  system.file("extdata", "vignette_population_individual_id_df.csv", package = "LAVA")
)

#write a vector of pop ids for genotyped parents
pop_id <- readRDS(
  system.file("extdata", "vignette_pop_id.rds", package = "LAVA")
)

cat("Trait data (first 6 rows):\n")
print(head(trait_df_pop))
cat("\n")

cat("Population-individual mapping (first 6 rows):\n")
print(head(population_individual_id))
cat("\n")

# Visualize trait distribution by population
cat("Creating trait distribution plot by population...\n")
unique_pops <- unique(trait_df_pop$population)
n_pops <- length(unique_pops)
colors <- rainbow(n_pops)

# Save plot as PNG
png("/home/isa/github_repositories/LAVA/vignettes/trait_distribution_by_population.png", 
    width = 800, height = 600)
plot(trait_df_pop$individual, trait_df_pop$trait,
     col = colors[as.factor(trait_df_pop$population)],
     pch = 19, cex = 0.8,
     xlab = "Individual ID", ylab = "Trait Value (standardized)",
     main = "Trait Distribution by Population")
legend("topright", legend = paste("Pop", unique_pops), 
       col = colors, pch = 19, cex = 0.8, bty = "n")
dev.off()
cat("Plot saved to vignettes/trait_distribution_by_population.png\n")
cat("\n")

cat("Step 3: Calculate coancestry matrices\n")
cat("------------------------------------------------------\n")

coancestries_dosage <- calculate_coancestries(
  genetic_data_parents = dos_P_neutral,
  genotyped_parent_populations = pop_id,
  genetic_data_F1 = dos_F1only_neutral,
  population_individual_id = population_individual_id,
  column_individual = "individual",
  column_population = "pop_id",
  all_parents_genotyped = TRUE,
  verbose = TRUE
)

Theta.P <- coancestries_dosage$Theta.P
M <- coancestries_dosage$M

#Or directly load pre-calculated matrices

Theta.P <- readRDS(
   system.file("extdata", "vignette_Theta_P.rds", package = "LAVA")
 )
M <- readRDS(
   system.file("extdata", "vignette_M.rds", package = "LAVA")
 ) 

cat("\nCoancestry matrices calculated:\n")
cat("  Theta.P dimensions:", dim(Theta.P), "\n")
cat("  M dimensions:", dim(M), "\n\n")

cat("Matrices saved to inst/extdata\n\n")

cat("Step 4: Run LAVA analysis\n")
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
cat("LAVA ANALYSIS RESULTS\n")
cat("================================================================\n\n")

# View concise summary
cat("Concise summary:\n")
summary(results)

cat("\n--- Detailed output ---\n")
print(results)

cat("\n--- Posterior samples ---\n")
cat("First 6 rows of posterior samples:\n")
print(head(results$sampling))

cat("\n--- Visualize posterior distribution ---\n")
png("/home/isa/github_repositories/LAVA/vignettes/posteriorplot.png", width = 800, height = 600)
plot(results)
dev.off()


saveRDS(results, file.path(save_path, "vignette_lava_results.rds"))
cat("\nResults saved to inst/extdata/vignette_lava_results.rds\n")

cat("Step 5: Load environmental data and run LAVA with environment\n")
cat("------------------------------------------------------\n")


trait_df_pop_env <- read.csv(
  system.file("extdata", "vignette_environment_df.csv", package = "LAVA")
)

cat("Trait data with environment (first 6 rows):\n")
print(head(trait_df_pop_env))
cat("\n")

cat("Environmental optima by population:\n")
env_by_pop <- aggregate(environment ~ population, data = trait_df_pop_env, FUN = mean)
print(env_by_pop)
cat("\n")

# Visualize trait vs environment
cat("Creating trait vs environment plot...\n")
png("/home/isa/github_repositories/LAVA/vignettes/trait_vs_environment.png", 
    width = 800, height = 600)
plot(trait_df_pop_env$environment, trait_df_pop_env$trait,
     col = colors[as.factor(trait_df_pop_env$population)],
     pch = 19, cex = 0.8,
     xlab = "Environmental Optimum", ylab = "Trait Value (standardized)",
     main = "Trait Value vs Environmental Optimum by Population")
legend("bottomright", legend = paste("Pop", unique_pops), 
       col = colors, pch = 19, cex = 0.8, bty = "n", ncol = 2)
dev.off()
cat("Plot saved to vignettes/trait_vs_environment.png\n\n")

# Run LAVA with environment
cat("Running LAVA analysis with environmental covariate\n")

results_env <- lava(
  Theta.P = Theta.P,
  M = M,
  trait_dataframe = trait_df_pop_env,
  column_individual = "individual",
  column_trait = "trait",
  formula_covariates = "environment",
  save_full_model = FALSE,
  iter = 4000,           
  warmup = 2000,         
  control = list(adapt_delta = 0.95, max_treedepth = 12)  
)

cat("\n")
cat("================================================================\n")
cat("LAVA ANALYSIS RESULTS WITH ENVIRONMENT\n")
cat("================================================================\n\n")

cat("Concise summary:\n")
summary(results_env)

cat("\n--- Detailed output ---\n")
print(results_env)

cat("\n--- Posterior samples ---\n")
cat("First 6 rows of posterior samples:\n")
print(head(results_env$sampling))

cat("\n--- Visualize posterior distribution ---\n")
png("/home/isa/github_repositories/LAVA/vignettes/posteriorplot_with_environment.png", 
    width = 800, height = 600)
plot(results_env)
dev.off()

saveRDS(results_env, file.path(save_path, "vignette_lava_results_env.rds"))
cat("\nResults saved to inst/extdata/vignette_lava_results_env.rds\n")
