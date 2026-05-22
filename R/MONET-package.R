#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @importFrom grDevices rgb
#' @importFrom graphics abline legend par points polygon
#' @importFrom stats density gaussian median quantile var
#' @importFrom brms brm VarCorr hypothesis as_draws_df
#' @importFrom hierfstat mat2vec
#' @importFrom dplyr select distinct count rename full_join mutate
#' @importFrom tidyr replace_na
#' @importFrom magrittr %>%
## usethis namespace: end
NULL

#' MONET: Log ratio of Ancestral Variances
#'
#' The MONET package provides tools for analyzing the log ratio 
#' of ancestral variances. This package helps researchers analyze genomic data
#' and evolutionary patterns through statistical methods specialized for variance analysis.
#' 
#' @section Main Functions:
#' The MONET package provides several key functions:
#' \itemize{
#'   \item \code{\link{monet}}: Main function for estimating log ratios of ancestral variances
#'   \item \code{\link{calculate_coancestries}}: Calculate coancestry matrices from genetic data
#'   \item \code{\link{kinship_from_pedigree}}: Calculate kinship matrix from pedigree data
#'   \item \code{\link{counting_blocks_matrix}}: Utility function for matrix block counting
#' }
#' 
#' @section Dependencies:
#' This package relies on:
#' \itemize{
#'   \item \pkg{brms}: For Bayesian mixed-effects modeling
#'   \item \pkg{hierfstat}: For population genetics calculations
#' }
#' 
#' @author Isabela do O \email{isabela.doo@@unil.ch}
#' 
#' @references 
#' Goudet & Weir (2023), do O et al (2025)
#' 
#' @name MONET-package
NULL