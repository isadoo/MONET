#' Vignette Population-Individual ID Mapping
#'
#' @name vignette_population_individual_id_df
#' @docType data
#'
#' @description
#' A data frame mapping F1 individuals to their populations of origin.
#' This dataset is used in the LAVA package vignette to demonstrate
#' how to organize population structure information for analysis.
#'
#' @format A data frame with 900 rows and 2 variables:
#' \describe{
#'   \item{pop_id}{Population identifier (integer 1-18). Each population represents
#'   a different source population in the common garden experiment.}
#'   \item{individual}{Individual identifier (integer 1-900). Unique ID for each
#'   F1 offspring measured in the common garden.}
#' }
#'
#' @details
#' This dataset contains 18 populations with 50 individuals each (900 total).
#' The individuals are F1 offspring from within-population crosses, raised in
#' a common garden environment. This structure is typical of local adaptation
#' studies where offspring from different source populations are raised under
#' standardized conditions.
#'
#' @usage data(vignette_population_individual_id_df)
#'
#' @examples
#' \dontrun{
#' # Load the data
#' pop_ind_df <- read.csv(
#'   system.file("extdata", "vignette_population_individual_id_df.csv", 
#'               package = "LAVA")
#' )
#' 
#' # Check population sizes
#' table(pop_ind_df$pop_id)
#' }
#'
#' @source Simulated data for package vignette demonstration
#' @keywords datasets
NULL

#' Vignette Trait Data
#'
#' @name vignette_trait_df_pop
#' @docType data
#'
#' @description
#' A data frame containing standardized trait measurements for F1 individuals
#' from 18 populations. This neutral trait dataset is used in the LAVA package
#' vignette to demonstrate testing for local adaptation.
#'
#' @format A data frame with 900 rows and 4 variables:
#' \describe{
#'   \item{individual}{Individual identifier (integer 1-900). Corresponds to
#'   the individual IDs in vignette_population_individual_id_df.}
#'   \item{trait}{Standardized trait value (numeric). The trait has been
#'   centered (mean = 0) and scaled (variance = 1).}
#'   \item{trait_id}{Trait identifier (integer, all values = 1). Allows for
#'   multi-trait extensions in future analyses.}
#'   \item{population}{Population identifier (integer 1-18). Indicates the
#'   source population for each individual.}
#' }
#'
#' @details
#' This dataset represents a quantitative trait measured on F1 offspring raised
#' in a common garden. The trait is simulated to represent neutral divergence
#' (i.e., no local adaptation) and is used to demonstrate the LAVA method's
#' behavior under the null hypothesis.
#'
#' The trait values are standardized for analysis, which is a requirement for
#' the lava() function.
#'
#' @usage data(vignette_trait_df_pop)
#'
#' @examples
#' \dontrun{
#' # Load the data
#' trait_df <- read.csv(
#'   system.file("extdata", "vignette_trait_df_pop.csv", package = "LAVA")
#' )
#' 
#' # Summary statistics
#' summary(trait_df$trait)
#' 
#' # Trait distribution by population
#' boxplot(trait ~ population, data = trait_df)
#' }
#'
#' @source Simulated data for package vignette demonstration
#' @keywords datasets
NULL

#' Vignette Population Coancestry Matrix (Theta.P)
#'
#' @name vignette_Theta_P
#' @docType data
#'
#' @description
#' A symmetric matrix containing between-population coancestry coefficients.
#' This matrix describes the mean relatedness between pairs of individuals
#' from different populations, relative to the ancestral population.
#'
#' @format A 18x18 numeric matrix where:
#' \describe{
#'   \item{Diagonal elements}{Mean within-population coancestry (self-coancestry)}
#'   \item{Off-diagonal elements}{Mean coancestry between pairs of populations}
#' }
#'
#' @details
#' The Theta.P matrix is calculated using the allele-sharing method of moments
#' from neutral genetic markers. It represents the probability of identity-by-descent
#' (IBD) between random alleles from different populations.
#'
#' This matrix is used as input to the lava() function to model between-population
#' genetic structure. Higher values indicate greater genetic similarity between
#' populations.
#'
#' The matrix is positive semi-definite and symmetric, with values typically
#' ranging from 0 to 1.
#'
#' @usage data(vignette_Theta_P)
#'
#' @examples
#' \dontrun{
#' # Load the data
#' Theta.P <- readRDS(
#'   system.file("extdata", "vignette_Theta_P.rds", package = "LAVA")
#' )
#' 
#' # Check dimensions
#' dim(Theta.P)
#' 
#' # Visualize population structure
#' heatmap(Theta.P, symm = TRUE)
#' }
#'
#' @seealso \code{\link{calculate_coancestries}} for computing Theta.P from genetic data
#' @source Calculated from simulated neutral marker data using hierfstat::fs.dosage()
#' @keywords datasets
NULL

#' Vignette Individual Relatedness Matrix (M)
#'
#' @name vignette_The_M
#' @docType data
#'
#' @description
#' A symmetric block-diagonal matrix containing within-population relatedness
#' coefficients for F1 individuals. This matrix describes the kinship between
#' pairs of individuals within populations, adjusted for population structure.
#'
#' @format A 900x900 numeric matrix where:
#' \describe{
#'   \item{Diagonal elements}{Self-relatedness (typically 1)}
#'   \item{Within-population blocks}{Adjusted relatedness between individuals
#'   from the same population}
#'   \item{Between-population elements}{Zero (no relatedness between populations)}
#' }
#'
#' @details
#' The M matrix represents the kinship-based relatedness among F1 individuals,
#' adjusted to account for the population structure captured in Theta.P. The
#' adjustment is: M_x = relatedness_x × (1 - Theta.P_xx)
#'
#' This matrix has a block-diagonal structure where:
#' \itemize{
#'   \item Each block corresponds to one population (50×50 for this dataset)
#'   \item Within blocks: non-zero values representing family structure
#'   \item Between blocks: zeros (individuals from different populations)
#' }
#'
#' The matrix is used as input to the lava() function to model within-population
#' genetic structure and family relationships.
#'
#' @usage data(vignette_The_M)
#'
#' @examples
#' \dontrun{
#' # Load the data
#' M <- readRDS(
#'   system.file("extdata", "vignette_The_M.rds", package = "LAVA")
#' )
#' 
#' # Check dimensions
#' dim(M)
#' 
#' # Verify block-diagonal structure
#' image(M[1:100, 1:100])  # First two populations
#' 
#' # Check eigenvalues (should be positive semi-definite)
#' min(eigen(M)$values)
#' }
#'
#' @seealso \code{\link{calculate_coancestries}} for computing M from genetic data or pedigree
#' @source Calculated from simulated F1 neutral marker data using hierfstat::beta.dosage()
#' @keywords datasets
NULL

#' Vignette LAVA Results
#'
#' @name vignette_lava_results
#' @docType data
#'
#' @description
#' An example output object from the lava() function, demonstrating the
#' structure and content of LAVA analysis results. This object contains
#' posterior samples, log-ratio estimates, and convergence diagnostics.
#'
#' @format A list of class "lava" with the following components:
#' \describe{
#'   \item{sampling}{Data frame of posterior samples containing fixed effects,
#'   variance components (var_pop, var_ind), and log_ratio values}
#'   \item{log_ratio}{List with summary statistics: p_value, mean, median,
#'   ci_lower, ci_upper for the log-ratio of ancestral variances}
#'   \item{hypothesis}{Results from hypothesis test comparing population vs
#'   individual variance components}
#'   \item{trait_name}{Name of the analyzed trait column}
#'   \item{formula_used}{The brms model formula used in the analysis}
#'   \item{convergence}{List with n_divergent transitions and max_rhat values}
#' }
#'
#' @details
#' This example result is from analyzing the vignette_trait_df_pop dataset,
#' which represents a neutral trait (no local adaptation). The log-ratio
#' should be close to zero, indicating V_A,B ≈ V_A,W as expected under neutrality.
#'
#' The object can be used with print() and plot() methods to visualize results.
#'
#' @usage data(vignette_lava_results)
#'
#' @examples
#' \dontrun{
#' # Load the results
#' results <- readRDS(
#'   system.file("extdata", "vignette_lava_results.rds", package = "LAVA")
#' )
#' 
#' # Print summary
#' print(results)
#' 
#' # Plot posterior distribution
#' plot(results)
#' 
#' # Access log-ratio estimate
#' results$log_ratio$mean
#' }
#'
#' @seealso \code{\link{lava}} for generating these results
#' @source Generated by running lava() on vignette example data
#' @keywords datasets
NULL

#' Neutral Genetic Data (Parental Generation)
#'
#' @name neutral_data_g3000
#' @docType data
#'
#' @description
#' Neutral bi-allelic genetic marker data for 180 individuals from 18 populations
#' (10 individuals per population). This dataset represents the parental generation
#' used to create F1 offspring for common garden experiments.
#'
#' @format A data file in FSTAT format containing:
#' \describe{
#'   \item{Populations}{18 populations (10 individuals each)}
#'   \item{Loci}{2000 neutral bi-allelic markers}
#'   \item{Format}{FSTAT format: population ID followed by genotypes}
#' }
#'
#' @details
#' This file contains neutral genetic markers simulated to represent population
#' structure without selection. The data is in FSTAT format and can be read
#' using hierfstat::read.fstat().
#'
#' After reading, the data should be converted to dosage format using
#' hierfstat::biall2dos() for use with calculate_coancestries().
#'
#' The file structure:
#' \itemize{
#'   \item First line: n_populations n_loci n_digits_per_allele max_alleles_per_locus
#'   \item Subsequent lines: population_id genotype_locus1 genotype_locus2 ...
#' }
#'
#' @usage 
#' system.file("extdata", "neutral_data_g3000.dat", package = "LAVA")
#'
#' @examples
#' \dontrun{
#' # Read the data
#' neutral_file <- system.file("extdata", "neutral_data_g3000.dat", 
#'                             package = "LAVA")
#' sim <- hierfstat::read.fstat(fname = neutral_file)
#' 
#' # Convert to dosage format
#' dos <- hierfstat::biall2dos(sim[, -1])
#' pop <- sim$Pop
#' 
#' # Use in coancestry calculation
#' # See vignette for complete workflow
#' }
#'
#' @source Simulated neutral marker data
#' @keywords datasets
NULL

#' Quantitative Trait Loci Data (Parental Generation)
#'
#' @name quanti_trait_g3000
#' @docType data
#'
#' @description
#' Bi-allelic genetic marker data for quantitative trait loci (QTL) from 180
#' individuals across 18 populations. This dataset represents causal loci
#' underlying a quantitative trait in the parental generation.
#'
#' @format A data file in FSTAT format containing:
#' \describe{
#'   \item{Populations}{18 populations (10 individuals each)}
#'   \item{Loci}{100 bi-allelic QTL markers}
#'   \item{Format}{FSTAT format: population ID followed by genotypes}
#' }
#'
#' @details
#' This file contains genetic markers at loci that influence a quantitative trait.
#' Unlike the neutral markers in neutral_data_g3000.dat, these loci have phenotypic
#' effects and are used to simulate trait values in the F1 generation.
#'
#' The data is in FSTAT format and should be read using hierfstat::read.fstat(),
#' then converted to dosage format with hierfstat::biall2dos().
#'
#' These markers can be used to:
#' \itemize{
#'   \item Simulate trait values in offspring
#'   \item Understand the genetic architecture of traits
#'   \item Create realistic scenarios for testing local adaptation
#' }
#'
#' @usage 
#' system.file("extdata", "quanti_trait_g3000.dat", package = "LAVA")
#'
#' @examples
#' \dontrun{
#' # Read the data
#' quanti_file <- system.file("extdata", "quanti_trait_g3000.dat", 
#'                            package = "LAVA")
#' sim_quanti <- hierfstat::read.fstat(fname = quanti_file)
#' 
#' # Convert to dosage format
#' dos_quanti <- hierfstat::biall2dos(sim_quanti[, -1], diploid = TRUE)
#' }
#'
#' @source Simulated QTL data with additive genetic effects
#' @keywords datasets
NULL

#' F1 Neutral Dosage Data
#'
#' @name vignette_dos_F1only_neutral
#' @docType data
#'
#' @description
#' Genetic marker data in dosage format for 900 F1 individuals at 2000 neutral loci.
#' This dataset represents offspring genotypes from within-population crosses.
#'
#' @format A 900×2000 numeric matrix where:
#' \describe{
#'   \item{Rows}{900 F1 individuals (50 per population × 18 populations)}
#'   \item{Columns}{2000 neutral loci}
#'   \item{Values}{Dosage format: 0 (homozygote reference), 1 (heterozygote),
#'   2 (homozygote alternate)}
#' }
#'
#' @details
#' This matrix contains neutral genetic markers for F1 offspring in dosage format,
#' which is required input for calculate_coancestries(). The dosage format
#' represents the number of reference alleles each individual carries.
#'
#' The F1 individuals were generated through within-population crosses from the
#' parental generation (neutral_data_g3000.dat). This data is used to calculate
#' the M matrix (within-population relatedness).
#'
#' @usage data(vignette_dos_F1only_neutral)
#'
#' @examples
#' \dontrun{
#' # Load the data
#' dos_F1 <- readRDS(
#'   system.file("extdata", "vignette_dos_F1only_neutral.rds", package = "LAVA")
#' )
#' 
#' # Check dimensions
#' dim(dos_F1)  # 900 individuals × 2000 loci
#' 
#' # Summary of dosage values
#' table(dos_F1[1:10, 1:10])
#' }
#'
#' @seealso \code{\link{calculate_coancestries}} for using this data to compute relatedness matrices
#' @source Generated from simulated crosses using parental neutral marker data
#' @keywords datasets
NULL

#' F1 Quantitative Trait Dosage Data
#'
#' @name vignette_dosage_quanti_F1
#' @docType data
#'
#' @description
#' Genetic marker data in dosage format for 900 F1 individuals at 100 quantitative
#' trait loci (QTL). This dataset is used to simulate phenotypic trait values.
#'
#' @format A 900×100 numeric matrix where:
#' \describe{
#'   \item{Rows}{900 F1 individuals (50 per population × 18 populations)}
#'   \item{Columns}{100 QTL markers}
#'   \item{Values}{Dosage format: 0, 1, or 2 representing genotype at each QTL}
#' }
#'
#' @details
#' This matrix contains QTL marker data for F1 offspring in dosage format.
#' These markers have additive effects on the quantitative trait and are used
#' to generate the trait values found in vignette_trait_df_pop.csv.
#'
#' The trait was simulated as:
#' \deqn{Y = \sum_{i=1}^{100} (dosage_i - 1) \times 0.2 + error}
#'
#' where error ~ N(0, 1), and the trait was then standardized.
#'
#' @usage data(vignette_dosage_quanti_F1)
#'
#' @examples
#' \dontrun{
#' # Load the data
#' dos_quanti_F1 <- readRDS(
#'   system.file("extdata", "vignette_dosage_quanti_F1.rds", package = "LAVA")
#' )
#' 
#' # Check dimensions
#' dim(dos_quanti_F1)  # 900 individuals × 100 QTL
#' }
#'
#' @source Generated from simulated crosses using parental QTL data
#' @keywords datasets
NULL
