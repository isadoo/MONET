#' Check if input is a numeric vector
#'
#' This function checks if the provided input is a numeric vector.
#'
#' @param x Object to check
#' @return Logical value indicating if x is a numeric vector
#' @keywords internal
#'
#' @examples
#' \dontrun{
#' is_numeric_vector(1:10)  # TRUE
#' is_numeric_vector("test")  # FALSE
#' }
is_numeric_vector <- function(x) {
  is.numeric(x) && is.vector(x)
}

#' Check if input is a positive numeric vector
#'
#' This function checks if the provided input is a numeric vector with all positive values.
#'
#' @param x Object to check
#' @return Logical value indicating if x is a positive numeric vector
#' @keywords internal
#'
#' @examples
#' \dontrun{
#' is_positive_numeric(1:10)  # TRUE
#' is_positive_numeric(c(-1, 2, 3))  # FALSE
#' }
is_positive_numeric <- function(x) {
  is_numeric_vector(x) && all(x > 0)
}