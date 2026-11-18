###########################################################################
#' @title Calculate coancestries
#'
#' @description Given genetic data it provides coancestry for between and within populations
#' 
#' @usage calculate_coancestries(genetic_data_parents, genotyped_parent_populations, 
#'   genetic_data_F1 = NA, population_individual_id = NA, 
#'   column_individual = "id", column_population = "population_id", 
#'   pedigree = NA, all_parents_genotyped = FALSE, verbose = TRUE, nearPD = TRUE)
#'
#' @param genetic_data_parents A data frame or file name containing genetic data for the parental generation. Must be dosage format.
#' 
#' @param genotyped_parent_populations A vector of population IDs for the parental generation.
#'
#' @param genetic_data_F1 A data frame or file name containing genetic data for the F1 generation. Must be dosage format.
#' 
#' @param population_individual_id (Optional) A data frame mapping individuals to their respective populations.
#' If not provided, a balanced design is assumed.
#'
#' @param column_individual The name of the column containing individual IDs. Default is "id".
#'
#' @param column_population The name of the column containing population IDs. Default is "population_id".
#'
#' @param pedigree (Optional) A data frame with one row per individual and the columns \code{id},
#' \code{sire}, \code{dam}, \code{sire_pop} and \code{dam_pop}. Unknown parents are NA ("" and "0" are
#' also read as unknown). Parents named in \code{sire} or \code{dam} that are not rows of the pedigree
#' are added as unrelated, non-inbred founders, with a warning, so that their offspring are related;
#' they are not included in \code{M}.
#'
#' @param all_parents_genotyped Logical; if TRUE, indicates that the genotyped individuals in "genotyped_parent_populations" are the parents of F1 individuals
#' 
#' @param verbose Logical; if TRUE (default), prints informational messages during calculation. If FALSE, suppresses output.
#'
#' @param nearPD Logical; if TRUE (default), a Theta.P or M that is not positive definite is replaced
#' by the nearest positive definite matrix from \code{Matrix::nearPD()}, with a warning. If FALSE, it is
#' returned uncorrected, with a warning. \code{monet()} needs positive definite matrices, so with
#' \code{nearPD = FALSE} a matrix that is not positive definite must be corrected in another way first.
#'
#' @return A list containing:
#' \item{M}{A kinship-based relatedness matrix adjusted for F1 individuals.}
#' \item{Theta.P}{An adjusted population coancestry matrix.}
#' \item{M.raw}{M before the \code{nearPD} step. Identical to M when M is positive definite or
#' \code{nearPD = FALSE}.}
#' \item{Theta.P.raw}{Theta.P before the \code{nearPD} step. Identical to Theta.P when Theta.P is
#' positive definite or \code{nearPD = FALSE}.}
#'
#' @details This function calculates kinship and coancestry measures from genetic data
#' or pedigree-based information, adjusting for population structure and F1 generation characteristics.
#'
#' M depends on Theta.P: each population's block of M is multiplied by \eqn{1 - \theta_{pp}}, the
#' diagonal element of Theta.P for that population. With \code{nearPD = TRUE}, M and M.raw are built
#' with the corrected Theta.P, so correcting Theta.P also changes M slightly. With
#' \code{nearPD = FALSE}, they are built with the uncorrected Theta.P.
#'
#' @author Isabela do O \email{isabela.doo@@unil.ch}
#' @references
#' - Goudet & Weir (2023)
#'
#' @export

calculate_coancestries <- function(genetic_data_parents,
                                   genotyped_parent_populations, 
                                   genetic_data_F1 = NA, 
                                   population_individual_id = NA, 
                                   column_individual = "id", 
                                   column_population = "population_id", 
                                   pedigree = NA,
                                   all_parents_genotyped = FALSE,
                                   verbose = TRUE,
                                   nearPD = TRUE) {

    # Fix for R CMD check global variable notes
    dam <- dam_pop <- sire <- sire_pop <- id <- population_id <- n <- sire_n <- dam_n <- NULL

    if (!isTRUE(nearPD) && !isFALSE(nearPD)) stop("nearPD must be TRUE or FALSE")



    parent_dosage <- genetic_data_parents
    

    # Load F1 data and get kinship 
    if (!identical(pedigree, NA)) {
        # kinship2 treats an individual whose parents are not rows of the pedigree as a founder,
        # unrelated to everyone, including its sibs. Such parents are added as founders
        # (unrelated, non-inbred) so that their offspring are related, and dropped again below.
        ped_ids  <- as.character(pedigree$id)
        sire_ids <- as.character(pedigree$sire)
        dam_ids  <- as.character(pedigree$dam)
        sire_ids[sire_ids %in% c(NA, "", "0")] <- NA
        dam_ids[dam_ids %in% c(NA, "", "0")] <- NA
        missing_parents <- setdiff(unique(c(sire_ids, dam_ids)), c(ped_ids, NA))
        n_missing <- length(missing_parents)
        if (n_missing > 0) {
            warning(n_missing, " parent(s) named in the sire or dam column are not rows of the pedigree: ",
                    paste(missing_parents[seq_len(min(10, n_missing))], collapse = ", "),
                    if (n_missing > 10) ", ...",
                    "\nThey were added as unrelated, non-inbred founders so that their offspring are related. ",
                    "If one of them is a misspelling of an individual already in the pedigree, correct the pedigree.",
                    call. = FALSE)
        }

        # Kinship coefficients from the pedigree. kinship2 puts self-kinship (1 + F) / 2 on the diagonal
        # replace it by the inbreeding coefficient F, as beta.dosage() gives, 
        # so that kinship2grm() below turns it into the relationship matrix (1 + F on the diagonal)
        kinship_F1 <- as.matrix(kinship2::kinship(id = c(ped_ids, missing_parents),
                                                  dadid = c(sire_ids, rep(NA, n_missing)),
                                                  momid = c(dam_ids, rep(NA, n_missing))))
        kinship_F1 <- kinship_F1[seq_along(ped_ids), seq_along(ped_ids), drop = FALSE]
        diag(kinship_F1) <- 2 * diag(kinship_F1) - 1
        #Make sure individuals are arranged by their naming, which ideally follows the population naming
        #sorted_F1_names <- sort(rownames(kinship_F1))
        #kinship_F1 <- kinship_F1[sorted_F1_names, sorted_F1_names]

        pop_ids_F1 <- pedigree$dam_pop

        F1_id <- pedigree$id
    } else if (!identical(genetic_data_F1, NA)) {
        F1_dosage <- genetic_data_F1
       
        matching_matrix_F1 <- hierfstat::matching(F1_dosage) 
        kinship_F1 <- hierfstat::beta.dosage(matching_matrix_F1, MATCHING = TRUE)
        F1_id <- population_individual_id[,column_individual]
    } else {
        stop("Missing F1 data, either include pedigree or genetic data")
    }
   
    

    # Determine parental population IDs and F1 population IDs (which includes P) 
    if (!identical(pedigree, NA)) {
        population_names <- unique(pedigree$dam_pop)
        parent_pop_id <- genotyped_parent_populations #may differ from pedigree
        #Calculate population sizes for M
        dam_df <- pedigree %>%
            select(id = dam, population_id = dam_pop) %>%
            distinct()
        sire_df <- pedigree %>%
            select(id = sire, population_id = sire_pop) %>%
            distinct()
        id_df <- pedigree %>%
            select(id, population_id = dam_pop) %>%
            distinct()

        parent_pop_id_pedigree <- c(sire_df$population_id, dam_df$population_id)
        F1_pop_id <- id_df$population_id

        dam_per_pop <- dam_df %>%
                count(population_id)
        sire_per_pop <- sire_df %>% 
                count(population_id)
        F1_per_pop <- id_df %>%
                count(population_id)
        sire_per_pop <- sire_per_pop %>%
                rename(sire_n = n)
        dam_per_pop <- dam_per_pop %>%
            rename(dam_n = n)
        parent_per_pop <- full_join(sire_per_pop, dam_per_pop, by = "population_id") %>%
                mutate(
                    sire_n = replace_na(sire_n, 0),
                    dam_n = replace_na(dam_n, 0),
                    parent_n = sire_n + dam_n
                )
        
        population_sizes_F1 <- F1_per_pop$n
        population_sizes_P <- parent_per_pop$parent_n #On pedigree (may differ from genotyped)
        population_sizes <- population_sizes_P + population_sizes_F1 #On pedigree (may differ from genotyped)
    } else if (!identical(population_individual_id, NA)) {
        
            population_names <- unique(population_individual_id[, column_population])
            parent_pop_id <- genotyped_parent_populations
            F1_pop_id <- population_individual_id[, column_population] 
            #Calculate population sizes for M
            population_sizes_P <- as.data.frame(table(parent_pop_id))$Freq
            population_sizes_F1 <- as.data.frame(table(F1_pop_id))$Freq
            population_sizes <- population_sizes_P + population_sizes_F1
         
    } else {
            stop("Population data missing. \n
            Provide either population_individual_id \n")
    }
    

    if (verbose) cat("There are ", length(unique(parent_pop_id)), " populations. \n")

    if (exists("pop_ids_F1")) {
        if (!identical(pop_ids_F1,F1_pop_id)) {
            warning("Mismatch between ids in F1 genetic data or pedigree and population identification.\n")
        }
    } else {
        pop_ids_F1 <- F1_pop_id
    }



    #Theta_P calculation 
    #Matching matrix and kinship for parents
    matching_matrix_parents <- hierfstat::matching(parent_dosage)
    kinship_parents <- hierfstat::beta.dosage(matching_matrix_parents, MATCHING = TRUE)
    fst_founders <- hierfstat::fs.dosage(matching_matrix_parents, pop = parent_pop_id, matching = TRUE)

    if (verbose) cat("Calculating Theta.P \n")
    min_Fst <- min(hierfstat::mat2vec(fst_founders$FsM))
    Theta_P <- (fst_founders$FsM - min_Fst) / (1 - min_Fst)
    if (verbose) cat("Theta.P calculated with dimensions", dim(Theta_P), "\n")
    
    # Theta.P must be positive definite
    Theta_P_raw <- Theta_P
    Theta_P <- check_positive_definite(Theta_P, "Theta.P", nearPD)
    # -


    # M calculation --
    if (verbose) cat("Calculating M \n")
    
    # Check if population sizes are correct --
    total_individuals <- sum(population_sizes)
    total_individuals_F1 <- sum(population_sizes_F1)
    #cat("population sizes including F1 and Founders are ", population_sizes, "\n")
    #cat("total individuals are ", total_individuals, "\n")
    if (verbose) cat("population sizes of F1", population_sizes_F1, "\n")
    if (verbose) cat("total individuals are ", total_individuals_F1, "\n")

    

    #Calculate mean kinship per population of parental (founder) population
    unique_pops <- unique(F1_pop_id) #same number of populations in F1 and in P
    #Should be the same as population_names

    

    
    #Explaining following If statement:
    #If you don't have genetic info from the parents, 
    #then you cannot infer their relationship, 
    #so you have to assume it is zero 
    #when you use the pedigree to estimate relatedness in F1
    if(all_parents_genotyped == FALSE && !identical(pedigree, NA)){
        adjusted_kinship_F1 <- kinship_F1
    } else {
        #Adjust kinship for F1 individuals - we use the mean kinship of the founders to standardize M
        adjusted_kinship_F1 <- matrix(0,nrow=nrow(kinship_F1),ncol=nrow(kinship_F1))
        last_individual_counted <- 0
        mean_kinship_per_population <- sapply(unique_pops, function(pop) {
        pop_indices_P <- which(parent_pop_id == pop)
        mean(hierfstat::mat2vec(kinship_parents[pop_indices_P, pop_indices_P]))
        })
        
        for (pop in 0:(length(unique_pops) - 1)) {  #Version before May 14th 2025 allowed for dosage of phenotyped individuals to include founders. 
        # Find indices for this population's F1
            if (verbose) cat("pop: ", pop, "\n")

            #Adjusting F1 individuals' kinship matrix
            start_idx <- last_individual_counted + 1
            end_idx <- last_individual_counted + population_sizes_F1[pop+1]

                
            adjusted_kinship_F1[start_idx:end_idx, start_idx:end_idx] <- 
                (kinship_F1[start_idx:end_idx, start_idx:end_idx] - mean_kinship_per_population[pop+1]) / 
                (1 - mean_kinship_per_population[pop+1])

            #Update the last individual count tracker
            last_individual_counted <- end_idx
            }

    }

    
    M <- matrix(0, nrow = sum(population_sizes_F1), ncol = sum(population_sizes_F1))
    row.names(M) <- colnames(M) <- F1_id


    for (pop in unique_pops) {
    #Grab the indices for individuals from current population
        pop_indices <- which(pop_ids_F1 == pop)
        dim_current_population <- length(pop_indices)
        if (verbose) cat("There are", dim_current_population, "individuals in population", pop, "for calculating the M matrix\n")
        kin_block <- hierfstat::kinship2grm(adjusted_kinship_F1)[pop_indices, pop_indices]
        block_adjusted <- kin_block * (1 - Theta_P[pop, pop])
        M[pop_indices, pop_indices] <- block_adjusted
    }

    #The M must be positive definite
    M_raw <- M
    M <- check_positive_definite(M, "M", nearPD)

    if (verbose) cat("M calculated with dimensions ", dim(M), "\n")

    return(list(M = M, Theta.P = Theta_P, M.raw = M_raw, Theta.P.raw = Theta_P_raw))
}


# Check that a coancestry matrix is positive definite. If it is not, warn, and replace it by the
# nearest positive definite matrix from Matrix::nearPD() when nearPD is TRUE.
#' @noRd
check_positive_definite <- function(mat, name, nearPD) {
    eigenvalues <- eigen(mat, symmetric = TRUE, only.values = TRUE)$values
    if (!any(eigenvalues < 0)) return(mat)

    problem <- paste0(name, " is not positive definite (", sum(eigenvalues < 0),
                      " negative eigenvalue(s), minimum ", signif(min(eigenvalues), 3), "). ")
    if (nearPD) {
        mat <- as.matrix(Matrix::nearPD(mat)$mat)
        new_min <- min(eigen(mat, symmetric = TRUE, only.values = TRUE)$values)
        warning(problem, "It was replaced by the nearest positive definite matrix from Matrix::nearPD() ",
                "(new minimum eigenvalue ", signif(new_min, 3), "). The uncorrected matrix is returned as ",
                name, ".raw.", call. = FALSE)
    } else {
        warning(problem, "It is returned uncorrected because nearPD = FALSE. monet() needs positive ",
                "definite matrices, so correct it before using it.", call. = FALSE)
    }
    mat
}
