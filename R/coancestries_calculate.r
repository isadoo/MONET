
###########################################################################
#' @title coancestries calculate
#'
#' @description Given genetic data it provides coancestry for between and within populations
#' 
#' @usage coancestries_calculate(genetic_data_parents, genetic_data_F1, datatype = "dosage", number_of_populations = NA, population_individual_id = NA, pedigree = NA, usepedigree = FALSE, BiAllelic = TRUE)
#'
#' @param genetic_data_parents A data frame or file name containing genetic data for the parental generation.
#' The format should match the specified datatype (e.g., dosage, VCF, or dat which is FSTAT format).
#'
#' @param genetic_data_F1 A data frame or file name containing genetic data for the F1 generation.
#' The format should match the specified datatype (e.g., dosage, VCF, or dat which is FSTAT format).
#' 
#' @param number_of_populations (Optional) A scalar indicating the number of populations.
#'
#' @param population_individual_id (Optional) A data frame mapping individuals to their respective populations. First parent ids, then F1 ids.
#' If not provided, a balanced design is assumed.
#'
#' @param pedigree (Optional) A data frame containing pedigree information with at least three columns: 
#' individual ID, dam ID, and sire ID.
#'
#' @param usepedigree Logical; if TRUE, kinship calculations will be based on the pedigree rather than genetic data. 
#' Defaults to FALSE.
#'
#' @param datatype A character string specifying the type of genetic data: "dosage" (default), "dat" (dataframe), "FSTAT" format), 
#' or "vcf" (variant call format).
#'
#' @param BiAllelic Logical; if TRUE, assumes biallelic markers for certain genetic data formats. Defaults to TRUE.
#'
#' @return A list containing:
#' \item{The.M}{A kinship-based relatedness matrix adjusted for F1 individuals.}
#' \item{Theta.P}{An adjusted population coancestry matrix.}
#'
#' @details This function calculates kinship and coancestry measures from genetic data 
#' or pedigree-based information, adjusting for population structure and F1 generation characteristics.
#'
#' @author Isabela do O \email{isabela.doo@@unil.ch}
#' @references
#' - Goudet & Weir (2023)
#'
#' @export

coancestries_calculate <- function(genetic_data_parents, genetic_data_F1, datatype = "dosage" , number_of_populations = NA, population_individual_id = NA, pedigree = NA, usepedigree = FALSE, BiAllelic = TRUE) {

    # Load parental genetic data and convert to dosage format
    if (datatype == "dosage") {
        parent_dosage <- genetic_data_parents
    } else if (datatype == "dat") {
        parent_data <- genetic_data_parents
        parent_dosage <- hierfstat::biall2dos(genetic_data_parents[,-1])
    } else if (datatype == "FSTAT") {
        parent_data <- hierfstat::read.fstat(fname = genetic_data_parents)
        parent_dosage <- hierfstat::biall2dos(parent_data[,-1])
    } else if (datatype == "vcf") {
        parent_data <- hierfstat::read.VCF(genetic_data_parents, convert = TRUE)
        parent_dosage <- as.matrix(parent_data)
    } else {
        stop("Invalid data type")
    }

    #Determine population ID
    if (!identical(population_individual_id, NA)) {
        pop_ids <- population_individual_id[1:nrow(parent_dosage), 1]
    } else if (!identical(number_of_populations, NA)) {
        individuals_per_pop <- nrow(parent_dosage) / number_of_populations
        pop_ids <- rep(1:number_of_populations, each = individuals_per_pop)
    } else if (datatype == "dat" || datatype == "FSTAT") {
        pop_ids <- parent_data[, 1]
    } else {
        stop("Population data missing. Provide either population_individual_id or number_of_populations.")
    }

    cat("There are ", length(unique(pop_ids)), " populations\n")

    #Matching matrix and kinship for parents
    matching_matrix_parents <- hierfstat::matching(parent_dosage)
    kinship_parents <- hierfstat::beta.dosage(matching_matrix_parents, MATCHING = TRUE)
    fst_founders <- hierfstat::fs.dosage(matching_matrix_parents, pop = pop_ids, matching = TRUE)

    cat("Calculating Theta.P \n")
    min_Fst <- min(hierfstat::mat2vec(fst_founders$FsM))
    Theta_P <- (fst_founders$FsM - min_Fst) / (1 - min_Fst)
    cat("Theta.P calculated with dimensions", dim(Theta_P), "\n")

    #check F1 data
    if (usepedigree == FALSE) {
        if (datatype == "dosage") {
            F1_dosage <- genetic_data_F1
        } else if (datatype == "dat" && BiAllelic == TRUE){
            F1_data <- genetic_data_F1 
            F1_dosage <- hierfstat::biall2dos(genetic_data_F1[,-1]) 
        } else if (datatype == "FSTAT" && BiAllelic == TRUE) {
            F1_data <- hierfstat::read.fstat(fname = genetic_data_F1)
            F1_dosage <- hierfstat::biall2dos(F1_data[,-1])
        } else if (datatype == "dat" && BiAllelic == FALSE) {
            F1_data <- genetic_data_F1
            F1_dosage <- hierfstat::fstat2dos(F1_data[,-1])
        } else if (datatype == "FSTAT" && BiAllelic == FALSE) {
            F1_data <- hierfstat::read.fstat(fname = genetic_data_F1)
            F1_dosage <- hierfstat::fstat2dos(F1_data[,-1])
        } else if (datatype == "vcf") {
            F1_data <- hierfstat::read.VCF(genetic_data_F1, convert = TRUE)
            F1_dosage <- as.matrix(F1_data)
        } else {
            stop("Invalid data type")
        }
        matching_matrix_F1 <- hierfstat::matching(F1_dosage)
        kinship_F1 <- hierfstat::beta.dosage(matching_matrix_F1, MATCHING = TRUE)
    } else {
        kinship_F1 <- kinship_from_pedigree(pedigree)
    }

   #Calculate mean kinship per population
    unique_pops <- unique(pop_ids)
    mean_kinship_per_population <- sapply(unique_pops, function(pop) {
        pop_indices <- which(pop_ids == pop)
        mean(mat2vec(kinship_parents[pop_indices, pop_indices]))
    })
   

    #Adjust kinship for F1 individuals
    adjusted_kinship_F1 <- kinship_F1
    for (pop in unique_pops) {
        pop_indices <- which(pop_ids == pop)
        adjusted_kinship_F1[pop_indices, pop_indices] <- 
            (kinship_F1[pop_indices, pop_indices] - mean_kinship_per_population[pop]) / 
            (1 - mean_kinship_per_population[pop])
    }

    #M matrix allowing for variable F1 population size
    cat("Calculating The.M \n")
    The.M <- matrix(0, nrow = nrow(kinship_F1), ncol = nrow(kinship_F1))
    for (pop in unique_pops) {
        pop_indices <- which(pop_ids == pop)
        The.M[pop_indices, pop_indices] <- 
            hierfstat::kinship2grm(adjusted_kinship_F1)[pop_indices, pop_indices] * (1 - Theta_P[pop, pop])
    }

    print("number of non zero value sin the diagonal of The M  \n")
    
    print(sum(diag(The.M) != 0))

    #The M must be positive definite
    eigenvalues <- eigen(The.M)$values
    if (any(eigenvalues < 0)) {
        print("M matrix not positive Definite \n")
    }

    cat("The.M calculated with dimensions ", dim(The.M), "\n")

    return(list(The.M = The.M, Theta.P = Theta_P))
}


## If only genetic_data_F1 is provided use the same data for both function entries.
## If genetic_data_parents is not available and instead there is a pedigree, then turn usepedigree to TRUE
### genetic_data should be a data frame with individual identifier and genotypes. 
#### In case of non even breeding desings: population_individual_id is a table/data frame that identifies which individual comes from which population.

#pedigree data frame should follow: id, sire, dam, sire_pop, dam_pop.