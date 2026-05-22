###########################################################################
#' @title Kinship Matrix from Pedigree
#'
#' @description Generates a kinship matrix from a pedigree data frame. 
#' The matrix represents the relatedness between individuals based on shared parents.
#'
#' @usage kinship_from_pedigree(pedigree)
#'
#' @param pedigree A data frame with three columns: 
#' \itemize{
#'   \item{\code{id}: Individual IDs (unique for each individual).}
#'   \item{\code{sire}: IDs of the sire (father); NA for founders.}
#'   \item{\code{dam}: IDs of the dam (mother); NA for founders.}
#' }
#'
#' @return A symmetric kinship matrix where rows and columns are labeled with individual IDs. 
#' Diagonal elements represent self-relatedness (1), and off-diagonal elements represent relatedness between individuals.
#' 
#' @details The function computes kinship coefficients under the assumption of non-inbred founders.
#' Half-sibling relationships (shared sire or dam) yield a coefficient of \eqn{\frac{1}{4}}. 
#' If individuals share both parents (full siblings), their kinship coefficient is \eqn{\frac{1}{4} + \frac{1}{4} = \frac{1}{2}}.
#' 
#' Note: This function uses \code{kinship2::kinship()} internally and converts the kinship coefficients
#' to a relatedness matrix by multiplying by 2.
#'
#' @examples
#' # Create a simple pedigree
#' pedigree <- data.frame(
#'   id = c("A", "B", "C", "D"),
#'   sire = c(NA, NA, "A", "A"),
#'   dam = c(NA, NA, "B", "B")
#' )
#' 
#' # Calculate kinship matrix
#' kinship_matrix <- kinship_from_pedigree(pedigree)
#'
#' @author Isabela do O \email{isabela.doo@@unil.ch}
#' 
#' @references 
#' Lynch, M., & Walsh, B. (1998). Genetics and analysis of quantitative traits. 
#' Sinauer Associates.
#' 
#' @keywords internal
kinship_from_pedigree <- function(pedigree) {
  
  # Use kinship2::kinship function
  # The kinship2::kinship function returns kinship coefficients (values 0-0.5)
  # We need to convert to a relatedness matrix (values 0-1) by multiplying by 2
  kinship_raw <- kinship2::kinship(id = pedigree$id, 
                                    dadid = pedigree$sire, 
                                    momid = pedigree$dam)
  
  # Convert kinship coefficients to relatedness matrix
  kinship_matrix <- as.matrix(kinship_raw * 2)
  rownames(kinship_matrix) <- colnames(kinship_matrix) <- pedigree$id
  
  return(kinship_matrix)
}