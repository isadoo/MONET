#' @title monet: Log ratios of ancestral variances
#'
#' @description Given coancestry matrices for between and within populations and a trait data frame, 
#' this function estimates the log ratio of ancestral variances using a Bayesian mixed-effects model.
#' 
#' @usage monet(Theta.P, M, trait_dataframe, column_individual = "id", column_trait = "trait", 
#'             column_population = "population", column_se = NULL, formula_covariates = NULL, 
#'             iter = 5000, warmup = 2000, thin = 2, save_full_model = FALSE,
#'             standardize_trait = NULL, formula = NULL, ...)
#'
#' @param Theta.P A square matrix representing the coancestry matrix between populations.
#' Must be positive definite (see the \code{nearPD} argument of \code{calculate_coancestries()}).
#'
#' @param M A square matrix representing the kinship-based relatedness matrix for individuals.
#' Must be positive definite (see the \code{nearPD} argument of \code{calculate_coancestries()}).
#'
#' @param trait_dataframe A data frame containing individual IDs and trait values. 
#' The first column should be individual IDs, and the second column should be trait values.
#'
#' @param column_individual The name of the column containing individual IDs. Default is "id".
#'
#' @param column_trait The name of the column containing trait values. Default is "trait".
#'
#' @param column_population The name of the column containing population IDs. Default is "population".
#'
#' @param column_se The name of the column containing standard errors of trait values. Default is NULL (no SEs).
#' If provided, the function will incorporate measurement error in the model.
#' 
#' @param formula_covariates A character string specifying additional covariates to include in the model.
#' For example, "age + sex" would add age and sex as fixed effects. Default is NULL (no covariates).
#' Use either formula_covariates or formula.
#' 
#' @param iter Number of MCMC iterations per chain. Default is 5000.
#' 
#' @param warmup Number of warmup (burn-in) iterations per chain. Default is 2000.
#' 
#' @param thin Thinning rate for the MCMC sampler. Default is 2 (every 2nd sample is kept).
#' 
#' @param save_full_model Logical. If TRUE, saves the full brms model object in the results.
#' If FALSE (default), only minimal posterior samples (fixed effects, variance components, and log-ratio) are retained to save memory.
#'
#' @param standardize_trait Logical or NULL. Controls z-score standardization of the response trait.
#' If TRUE, always standardize (unless variance is zero/non-finite). If FALSE, does NOT standardize.
#' If NULL (default), the function auto-detects likely discrete traits (integer-like with <= 10 unique values)
#' and skips standardization for those traits.
#' 
#' @param formula Optional. A full model formula that replaces the default one: a formula, a character
#' string or a \code{brms::bf()} formula (for example with \code{sigma ~ sex}). The response must be
#' \code{Y} (the trait in column_trait), and the formula must keep a population effect with Theta.P,
#' \code{gr(pop, cov = two.Theta.P)}, and an individual effect with M, \code{gr(ind, cov = M)};
#' otherwise monet() stops. Other variables must be columns of trait_dataframe. With column_se, write
#' the measurement error in the response, e.g. \code{Y | se(Y_se, sigma = TRUE) ~ ...}.
#' Default is NULL: \code{Y ~ 1 + (1 | gr(pop, cov = two.Theta.P)) + (1 | gr(ind, cov = M))}.
#'
#' @param ... Additional arguments passed to the brms function.
#'
#' @return A monet type object containing:
#' \item{sampling}{Either the full brms model object (if save_full_model = TRUE) or a data frame with minimal posterior samples including fixed effects, the standard deviations and correlations of the pop and ind random effects, variance components (V_AB, V_AW), and log_ratio. When the log ratio is computed for several coefficients, V_AB, V_AW and log_ratio are suffixed with the coefficient (e.g. log_ratio_sexF).}
#' \item{log_ratio}{A data frame with one row per random-effect coefficient present in both the pop and the ind terms (Intercept for the default formula; e.g. sexF and sexM for \code{(0 + sex | ...)}) and the columns: coefficient, p_value (two-tailed test that log-ratio differs from 0), mean (mean of log-ratio posterior), median (median of log-ratio posterior), ci_lower and ci_upper (95% credible interval bounds). NULL if no coefficient is shared.}
#' \item{covariate_p_values}{Named numeric vector with two-tailed posterior sign-probability p-values for fixed-effect covariates (excluding intercept). NULL when no covariates are present.}
#' \item{hypothesis}{Results from brms hypothesis test comparing population vs individual variance.}
#' \item{trait_name}{Name of the trait column analyzed.}
#' \item{formula_used}{The model formula used in the analysis.}
#' \item{convergence}{A list containing n_divergent (number of divergent transitions) and max_rhat (maximum R-hat value across parameters).}
#' 
#' @details This function standardizes trait data, constructs a Bayesian mixed-effects model using `brms`,
#' and it estimates ancestral variances. The function assumes no crosses between populations and analyzes one trait at a time
#'
#'
#' With \code{formula}, any brms model can be fitted as long as it keeps the Theta.P and M terms. For
#' example, sex-specific variances:
#' \code{brms::bf(Y ~ sex * habitat + (0 + sex | gr(pop, cov = two.Theta.P)) + (0 + sex | gr(ind, cov = M)), sigma ~ sex)}
#' gives one log ratio for each sex. Quantities that combine coefficients, such as the log ratio for sexual dimorphism
#' can be computed from the returned standard deviations and correlations.
#'
#' @author Isabela do O \email{isabela.doo@@unil.ch}
#'
#' @references 
#' 
#' - Goudet & Weir (2023)
#' - do O et al (2025)
#'
#' @export
monet <- function(Theta.P, 
                 M, 
                 trait_dataframe, 
                 column_individual = "id", 
                 column_trait = "trait", 
                 column_population = "population",
                 column_se = NULL,
                 formula_covariates = NULL,
                 iter = 5000, warmup = 2000, thin = 2,
                 save_full_model = FALSE,
                 standardize_trait = NULL,
                 formula = NULL,
                 ...) {
  
  #check input types and dimensions 
  if (!is.matrix(Theta.P) || !is.matrix(M)) {
    stop("Theta.P and M must be matrices.")
  }

  # Theta.P and M are used as covariance matrices, so they must be positive definite
  coancestry_matrices <- list(Theta.P = Theta.P, M = M)
  for (name in names(coancestry_matrices)) {
    eigenvalues <- eigen(coancestry_matrices[[name]], symmetric = TRUE, only.values = TRUE)$values
    if (any(eigenvalues < 0)) {
      warning("The coancestry matrix you've entered (", name, ") is not positive definite. ",
              "These matrices serve the role of a variance-covariance matrix. Thus, they need to be PD. ",
              "You can either rerun calculate_coancestries() with nearPD = TRUE or you should choose ",
              "your own method to make the matrix positive definite.", call. = FALSE)
    }
  }

  if (!is.data.frame(trait_dataframe) || ncol(trait_dataframe) < 2) {
    stop("trait_dataframe must be a data frame with at least two columns (ID and trait values).")
  }
 
  
  #extract columns by name if provided 
  id_col <- if(is.numeric(column_individual)) column_individual else which(names(trait_dataframe) == column_individual)
  trait_col <- if(is.numeric(column_trait)) column_trait else which(names(trait_dataframe) == column_trait)
  
  #Identify populations per individual
  population_blocks_df <- counting_blocks_matrix(M) #this function counts the number of blocks of non-zero rows in a matrix
  individuals_per_population_F1 <- population_blocks_df$rows
  number_of_blocks <- length(population_blocks_df$block) 
  pop_ids <- rep(1:number_of_blocks, individuals_per_population_F1[1:number_of_blocks]) 
  number_populations <- nrow(Theta.P)
  
  if (number_of_blocks != number_populations & !(column_population %in% names(trait_dataframe))) {
    warning(paste0("Mismatch between detected groups based on M matrix (", number_of_blocks,") and populations in Theta.P dimensions (", number_populations, ")\n
                   We have have no way of knowing what is the correct number of individuals in each subpopulation."))
  }
  
  Y_raw <- trait_dataframe[, trait_col]
  
  if (is.list(Y_raw)) {
    Y_raw <- unlist(Y_raw)
  }

  # Keep original values for coercion diagnostics
  Y_raw_chr <- as.character(Y_raw)
  
  # Ensure trait is numeric for current Gaussian-style model.
  # If non-numeric values exist, fail early with a clear message.
  Y <- suppressWarnings(as.numeric(Y_raw_chr))
  coercion_failed <- !is.na(Y_raw_chr) & nzchar(trimws(Y_raw_chr)) & is.na(Y)
  if (any(coercion_failed)) {
    bad_values <- unique(Y_raw_chr[coercion_failed])
    bad_preview <- paste(utils::head(bad_values, 5), collapse = ", ")
    stop(
      paste0(
        "Trait column contains non-numeric values and cannot be modeled with the current Gaussian response. ",
        "Example offending values: ", bad_preview, "."
      )
    )
  }
  
  #remove any NAs
  valid_indices <- !is.na(Y)
  Y <- Y[valid_indices]
  
  #Filter the dataframe to match
  trait_dataframe <- trait_dataframe[valid_indices, ]
  
  if (length(Y) < 2) {
    stop("Not enough non-missing numeric trait values after filtering.")
  }

  var_Y <- var(Y)
  n_unique_y <- length(unique(Y))
  integer_like <- all(abs(Y - round(Y)) < 1e-8)
    # Validate population column against Theta.P rownames (if population column exists in dataframe)
  if (column_population %in% names(trait_dataframe)) {
    pops_in_data <- unique(stats::na.omit(trait_dataframe[[column_population]]))
    pops_in_theta <- rownames(Theta.P)

    missing_pops <- setdiff(pops_in_data, pops_in_theta)
    if (length(missing_pops) > 0) {
      stop(
        paste0(
          "The following population IDs in column '", column_population,
          "' are not found in rownames(Theta.P): ",
          paste(missing_pops, collapse = ", ")
        )
      )
    }
  }

  # Determine whether to standardize
  if (is.null(standardize_trait)) {
    # Auto mode: skip standardization for likely discrete traits.
    do_standardize <- !(integer_like && n_unique_y <= 10)
    if (!do_standardize) {
      warning(
        "Trait appears discrete (integer-like with <= 10 unique values); skipping standardization in auto mode. ",
        "Set standardize_trait = TRUE to force z-score standardization."
      )
    }
  } else if (is.logical(standardize_trait) && length(standardize_trait) == 1 && !is.na(standardize_trait)) {
    do_standardize <- standardize_trait
  } else {
    stop("standardize_trait must be TRUE, FALSE, or NULL.")
  }

  if (do_standardize) {
    if (!is.finite(var_Y) || var_Y <= 0) {
      warning("Trait variance is non-finite or zero; skipping standardization.")
      do_standardize <- FALSE
    }
  }

  if (do_standardize) {
    Y <- Y - mean(Y)
    Y <- Y / sqrt(var_Y)
  }
  
  have_se <- !is.null(column_se) && (column_se %in% names(trait_dataframe))
  #Incorportate measurment errors (se) if provided
  if (have_se) {
    Y_se <- as.numeric(trait_dataframe[[column_se]])
    if (do_standardize) {
      Y_se <- Y_se / sqrt(var_Y)
    }
  }


  #From VB = VA*2FST
  two.Theta.P <- 2 * Theta.P

  ind_col <- trait_dataframe[,id_col]
  if (is.list(ind_col)) {
    ind_col <- unlist(ind_col)
  }
  ind_col <- as.character(ind_col)

  # Build an individual -> population lookup from M block structure.
  # If block count matches Theta.P dimension, use Theta.P rownames as labels.
  m_pop_lookup <- NULL
  if (!is.null(rownames(M))) {
    if (number_of_blocks == number_populations && !is.null(rownames(Theta.P))) {
      block_labels <- rownames(Theta.P)[seq_len(number_of_blocks)]
    } else {
      block_labels <- paste0("pop_", seq_len(number_of_blocks))
    }

    m_pop_labels <- rep(block_labels, individuals_per_population_F1[seq_len(number_of_blocks)])
    if (length(m_pop_labels) == nrow(M)) {
      names(m_pop_labels) <- rownames(M)
      m_pop_lookup <- m_pop_labels
    }
  }

  if (column_population %in% names(trait_dataframe)) {
    pop_col <- trait_dataframe[,column_population]
    if (is.list(pop_col)) {
      pop_col <- unlist(pop_col)
    }
    pop_col <- as.character(pop_col)

    overlap_with_thetap <- sum(pop_col %in% rownames(Theta.P), na.rm = TRUE)
    if (overlap_with_thetap == 0 && !is.null(m_pop_lookup)) {
      warning(
        sprintf(
          "column_population='%s' has zero overlap with rownames(Theta.P); using M-based population mapping from individual IDs instead.",
          column_population
        )
      )
      pop_col <- unname(m_pop_lookup[ind_col])
    }
  } else if (!is.null(m_pop_lookup)) {
    pop_col <- unname(m_pop_lookup[ind_col])
  } else if (length(pop_ids) == length(ind_col)) {
    pop_col <- paste0("pop_", pop_ids)
  } else {
    stop("Could not determine population labels from column_population or M block mapping.")
  }

  if (is.list(pop_col)) {
    pop_col <- unlist(pop_col)
  }
  pop_col <- as.character(pop_col)

  #Build the data frame
  dat <- data.frame(pop = pop_col, ind = ind_col, Y = Y)
  if (have_se) dat$Y_se <- Y_se

  # Align grouping levels with covariance matrix rownames.
  # brms requires the factor levels used in gr() to match the covariance matrix names exactly.
  if (is.null(rownames(M)) || is.null(rownames(Theta.P))) {
    stop("Theta.P and M must have rownames that identify grouping levels.")
  }

  keep_ind <- dat$ind %in% rownames(M)
  if (any(!keep_ind)) {
    warning(sprintf(
      "%d individuals were not represented in rownames(M), so they are not considered in the analysis.",
      sum(!keep_ind)
    ))
    dat <- dat[keep_ind, , drop = FALSE]
    trait_dataframe <- trait_dataframe[keep_ind, , drop = FALSE]
  }

  keep_pop <- dat$pop %in% rownames(Theta.P)
  if (any(!keep_pop)) {
    warning(sprintf(
      "Dropping %d rows whose pop values are not present in rownames(Theta.P).",
      sum(!keep_pop)
    ))
    dat <- dat[keep_pop, , drop = FALSE]
    trait_dataframe <- trait_dataframe[keep_pop, , drop = FALSE]
  }

  dat$ind <- factor(dat$ind, levels = rownames(M))
  dat$pop <- factor(dat$pop, levels = rownames(Theta.P))

  # Check a user formula: it must model Y and keep the Theta.P and M terms
  covariate_names <- NULL
  if (!is.null(formula)) {
    if (!is.null(formula_covariates)) {
      stop("Use either formula or formula_covariates, not both.")
    }
    if (is.character(formula)) formula <- stats::as.formula(formula)
    main_formula <- if (inherits(formula, "brmsformula")) formula$formula else formula
    if (!inherits(main_formula, "formula") || length(main_formula) != 3) {
      stop("formula must be a two-sided formula, a character string or a brms::bf() formula.")
    }
    if (!"Y" %in% all.vars(main_formula[[2]])) {
      stop("The response in formula must be Y, the trait given in column_trait.")
    }
    gr_terms <- find_gr_terms(main_formula[[3]])
    if (!"pop:two.Theta.P" %in% gr_terms || !"ind:M" %in% gr_terms) {
      stop("formula must keep a population effect with Theta.P, gr(pop, cov = two.Theta.P), ",
           "and an individual effect with M, gr(ind, cov = M), for example ",
           "(1 | gr(pop, cov = two.Theta.P)) + (1 | gr(ind, cov = M)).")
    }
    if (have_se && !"Y_se" %in% all.vars(main_formula[[2]])) {
      warning("column_se is not used: with formula, write the measurement error in the response, ",
              "e.g. Y | se(Y_se, sigma = TRUE) ~ ...", call. = FALSE)
    }
    other_formulas <- if (inherits(formula, "brmsformula")) formula$pforms else list()
    formula_vars <- c(all.vars(main_formula[[3]]),
                      unlist(lapply(other_formulas, function(f) all.vars(f[[length(f)]]))))
    covariate_names <- setdiff(unique(formula_vars), c("pop", "ind", "two.Theta.P", "M"))
  } else if (!is.null(formula_covariates)) {
    covariate_names <- unique(all.vars(stats::as.formula(paste("~", formula_covariates))))
  }

  # Add the covariates used by the model
  for (cov_name in covariate_names) {
    if (cov_name %in% names(trait_dataframe)) {
      cov_data <- trait_dataframe[, cov_name]
      if (is.list(cov_data)) cov_data <- unlist(cov_data)
      dat[[cov_name]] <- cov_data
    } else {
      stop(paste("Covariate", cov_name, "not found in trait_dataframe"))
    }
  }

  #Build the complete formula
  base_rhs <- "(1 | gr(pop, cov = two.Theta.P)) + (1 | gr(ind, cov = M))"
  rhs <- if (is.null(formula_covariates)) base_rhs else paste0(formula_covariates, " + ", base_rhs)

  if (!is.null(formula)) {
    model_formula <- formula
    formula_string <- paste(c(paste(deparse(main_formula, width.cutoff = 500L), collapse = " "),
                              vapply(other_formulas, function(f) paste(deparse(f, width.cutoff = 500L), collapse = " "), "")),
                            collapse = ", ")
  } else if (have_se) {
    # Use measurement error on the response; still estimate residual sigma
    formula_string <- paste0("Y | se(Y_se, sigma = TRUE) ~ 1 + ", rhs)
    model_formula <- brms::bf(stats::as.formula(formula_string))
    if (do_standardize) {
      cat("Measurement SE column: ", column_se, " (scaled to standardized Y)\n", sep = "")
    } else {
      cat("Measurement SE column: ", column_se, " (not scaled; trait not standardized)\n", sep = "")
    }
  } else {
    formula_string <- paste0("Y ~ 1 + ", rhs)
    model_formula <- stats::as.formula(formula_string)
  }
  
  cat("Using formula:", formula_string, "\n")
  
  #Diagnostics
  n_total <- nrow(dat)
  n_complete <- sum(stats::complete.cases(dat))
  cat("Total rows:", n_total, " ; complete rows used:", n_complete, "\n")
  
  #check for NAs
  na_counts <- colSums(is.na(dat))
  if (any(na_counts > 0)) {
    cat("Warning: NAs found in columns:\n")
    print(na_counts[na_counts > 0])
  }
  
  
  #Bayesian model - using brms package
  #Using tryCatch to handle convergence issues 
  brms_mf <- tryCatch({
    brm(
      formula = model_formula,
      data = dat,
      data2 = list(two.Theta.P = two.Theta.P, M = M), 
      iter = iter, warmup = warmup, thin = thin,
      ...
    )

  }, error = function(e) {
    cat("Error fitting model:", e$message, "\n")
    stop(e)
  })
  
  # Print summary properly
  cat("\n---- Model Summary ----\n")
  print(summary(brms_mf))
  cat("\n")
  
  # Check for convergence issues
  rhats <- brms::rhat(brms_mf)
  if (any(rhats > 1.01, na.rm = TRUE)) {
    warning("Some Rhat values > 1.01, indicating potential convergence issues")
  }

  
  
  
  # Extract sampling parameters directly from the fitted model
  iter   <- brms_mf$fit@sim$iter      # total iterations (including warmup)
  warmup <- brms_mf$fit@sim$warmup    # warmup iterations
  chains <- brms_mf$fit@sim$chains    # number of chains
  thin   <- brms_mf$fit@sim$thin      # thinning interval
  post_warmup_transitions <- (iter - warmup) * chains
  threshold_1pct <- 0.01 * post_warmup_transitions
  sampler_params <- brms::nuts_params(brms_mf)
  # get divergent transitions and check if its under 1%
  n_divergent    <- sum(sampler_params[sampler_params$Parameter == "divergent__", "Value"])
  if (n_divergent > 0) {
    warning(paste("Model had", n_divergent, "divergent transitions after warmup"))
  }

  # -> core draws we need <---
  # Get all draws once, then select columns we care about depending on save_full_model
  all_draws <- posterior::as_draws_df(brms_mf)

  fe_cols <- grep("^b_", names(all_draws), value = TRUE)                    # fixed effects
  re_cols <- grep("^(sd|cor)_(pop|ind)__", names(all_draws), value = TRUE)  # pop and ind random effects

  # Covariate p-values from posterior sign probability (exclude intercepts)
  covariate_p_values <- NULL
  cov_cols <- setdiff(fe_cols, c("b_Intercept", "b_sigma_Intercept"))
  if (length(cov_cols) > 0) {
    covariate_p_values <- sapply(cov_cols, function(col) {
      x <- all_draws[[col]]
      2 * min(mean(x >= 0, na.rm = TRUE), mean(x <= 0, na.rm = TRUE))
    })
    names(covariate_p_values) <- sub("^b_", "", cov_cols)
  }

  minimal_samples <- all_draws[, unique(c(fe_cols, re_cols)), drop = FALSE]

  # One log ratio per random-effect coefficient present in both the pop and the ind terms:
  # "Intercept" for the default formula, e.g. "sexF" and "sexM" for (0 + sex | ...)
  coefficients <- shared_coefficients(names(all_draws))
  suffix <- if (identical(coefficients, "Intercept")) "" else paste0("_", coefficients)
  names(suffix) <- coefficients
  log_ratio <- NULL
  hypothesis_table <- NULL

  if (length(coefficients) == 0) {
    warning("No random-effect coefficient is present in both the gr(pop, ...) and gr(ind, ...) terms, ",
            "so no log ratio was computed.", call. = FALSE)
  } else {
    for (k in coefficients) {
      V_AB <- minimal_samples[[paste0("sd_pop__", k)]]^2
      V_AW <- minimal_samples[[paste0("sd_ind__", k)]]^2
      minimal_samples[[paste0("V_AB", suffix[[k]])]] <- V_AB
      minimal_samples[[paste0("V_AW", suffix[[k]])]] <- V_AW
      minimal_samples[[paste0("log_ratio", suffix[[k]])]] <- log(V_AB / V_AW)
    }

    log_ratio <- do.call(rbind, lapply(coefficients, function(k) {
      lr <- minimal_samples[[paste0("log_ratio", suffix[[k]])]]
      data.frame(coefficient = k,
                 p_value = 2 * mean(sign(lr) != sign(stats::median(lr))),
                 mean = mean(lr),
                 median = stats::median(lr),
                 ci_lower = unname(stats::quantile(lr, 0.025)),
                 ci_upper = unname(stats::quantile(lr, 0.975)))
    }))

    hyp <- paste0("sd_pop__", coefficients, "^2 - sd_ind__", coefficients, "^2 = 0")
    the_hyp <- hypothesis(brms_mf, hyp, class = NULL)
    hypothesis_table <- the_hyp$hypothesis[2:5]
    rownames(hypothesis_table) <- coefficients
  }

  # ------------------------------------------------------------------------------------
   # ~~~~~~~~~~~~   # preparing results object # ~~~~~~~~~~~~~~~~~~
  # ------------------------------------------------------------------------------------
  results <- list(
  sampling = if (isTRUE(save_full_model)) {
    # Return the full brms model as 'sampling'
    brms_mf
  } else {
    # Minimal sampling: fixed effects + two RE SDs + var_* + log_ratio
    minimal_samples
  },

  log_ratio = log_ratio,

  covariate_p_values = covariate_p_values,

  hypothesis = hypothesis_table,
  trait_name = names(trait_dataframe)[trait_col],
  formula_used = formula_string,
  convergence = list(
    n_divergent = n_divergent,
    max_rhat = max(rhats, na.rm = TRUE)
  )
)
class(results) <- "monet"
return(results)
}
#' @export
print.monet <- function(x, ...) {
  cat("\n---- MONET Analysis Results ----\n\n")
  cat("Trait analyzed:", x$trait_name, "\n")
  cat("Formula used:", x$formula_used, "\n\n")
  
  cat("--- Log-Ratio of Ancestral Variances ---\n")
  if (is.null(x$log_ratio)) {
    cat("  Not computed (no random-effect coefficient shared by the pop and ind terms)\n\n")
  }
  for (i in seq_len(NROW(x$log_ratio))) {
    lr <- x$log_ratio[i, ]
    if (nrow(x$log_ratio) > 1) cat(" ", lr$coefficient, "\n")
    cat(sprintf("  Mean: %.4f\n", lr$mean))
    cat(sprintf("  Median: %.4f\n", lr$median))
    cat(sprintf("  95%% Credible Interval: [%.4f, %.4f]\n", lr$ci_lower, lr$ci_upper))
    cat(sprintf("  P-value: %.4f\n\n", lr$p_value))
  }

  cat("--- Convergence Diagnostics ---\n")
  cat(sprintf("  Max R-hat: %.4f", x$convergence$max_rhat))
  if (x$convergence$max_rhat > 1.01) {
    cat(" (WARNING: > 1.01)\n")
  }
  
  cat(sprintf("  Divergent transitions: %d", x$convergence$n_divergent))
  if (x$convergence$n_divergent > 0) {
    cat(" (WARNING: Consider increasing adapt_delta)\n")
  }
  
  cat("\nUse plot() to visualize the posterior distribution.\n\n")
  invisible(x)
}

#' @export
summary.monet <- function(object, ...) {
  cat("\n---- MONET Summary ----\n\n")
  cat(sprintf("Trait: %s\n\n", object$trait_name))
  
  cat("Log-Ratio of Ancestral Variances (log(VB/VA)):\n")
  if (is.null(object$log_ratio)) {
    cat("  Not computed (no random-effect coefficient shared by the pop and ind terms)\n")
  }
  for (i in seq_len(NROW(object$log_ratio))) {
    lr <- object$log_ratio[i, ]
    if (nrow(object$log_ratio) > 1) cat(" ", lr$coefficient, "\n")
    cat(sprintf("  Mean:   %7.4f\n", lr$mean))
    cat(sprintf("  Median: %7.4f\n", lr$median))
    cat(sprintf("  95%% CI: [%.4f, %.4f]\n", lr$ci_lower, lr$ci_upper))
    cat(sprintf("  p-value: %.4f %s\n", lr$p_value, ifelse(lr$p_value < 0.05, "*", "")))
  }

  if (!is.null(object$covariate_p_values) && length(object$covariate_p_values) > 0) {
    cat("\nCovariate posterior p-values:\n")
    for (nm in names(object$covariate_p_values)) {
      pv <- object$covariate_p_values[[nm]]
      cat(sprintf("  %s: %.4g\n", nm, pv))
    }
  }

  cat("\n")
  invisible(object)
}

#' @export
plot.monet <- function(x, ...) {
  # Accept either a brmsfit (full model) or a draws data.frame in x$sampling
  if (inherits(x$sampling, "brmsfit")) {
    # compute log_ratio from the model draws, one per coefficient shared by pop and ind
    draws <- posterior::as_draws_df(x$sampling)
    coefficients <- shared_coefficients(names(draws))
    if (length(coefficients) == 0) {
      stop("Could not find sd_pop__<coefficient>/sd_ind__<coefficient> in model draws to compute log_ratio.")
    }
    log_ratios <- lapply(coefficients, function(k) {
      log(draws[[paste0("sd_pop__", k)]]^2 / draws[[paste0("sd_ind__", k)]]^2)
    })
    names(log_ratios) <- coefficients
  } else {
    samp <- x$sampling
    lr_cols <- grep("^log_ratio", names(samp), value = TRUE)
    if (is.null(samp) || length(lr_cols) == 0) {
      stop("No 'log_ratio' samples found.")
    }
    log_ratios <- lapply(lr_cols, function(col) samp[[col]])
    names(log_ratios) <- sub("^log_ratio_?", "", lr_cols)
  }

  if (length(log_ratios) > 1) {
    old_par <- par(mfrow = c(1, length(log_ratios)))
    on.exit(par(old_par))
  }

  for (k in names(log_ratios)) {
    lr  <- log_ratios[[k]]
    med <- stats::median(lr)
    ci  <- stats::quantile(lr, c(0.025, 0.975))

    d <- stats::density(lr)
    plot(d, main = if (length(log_ratios) > 1) paste("Posterior of log-ratio:", k) else "Posterior of log-ratio",
      xlab = "LogAV", ylab = "Posterior density")
      abline(v = med, lty = 2)
      abline(v = ci, lty = 3)
      legend("topright",
          legend = c(paste0("median = ", round(med, 3)),
                      paste0("95% CI [", round(ci[1], 3), ", ", round(ci[2], 3), "]")),
          lty = c(2, 3), bty = "n")
  }

  invisible(NULL)
}


# Grouping variable and covariance matrix of each gr() term in a formula, as "group:cov"
#' @noRd
find_gr_terms <- function(expr) {
  if (!is.call(expr)) return(NULL)
  if (identical(expr[[1]], as.name("gr"))) {
    args <- as.list(expr)[-1]
    arg_names <- if (is.null(names(args))) rep("", length(args)) else names(args)
    group <- if (any(arg_names == "")) paste(deparse(args[arg_names == ""][[1]]), collapse = "") else ""
    cov <- if ("cov" %in% arg_names) paste(deparse(args[["cov"]]), collapse = "") else ""
    return(paste0(group, ":", cov))
  }
  unlist(lapply(as.list(expr)[-1], find_gr_terms))
}

# Random-effect coefficients estimated for both pop and ind, from the names of the posterior draws
#' @noRd
shared_coefficients <- function(draw_names) {
  intersect(sub("^sd_pop__", "", grep("^sd_pop__", draw_names, value = TRUE)),
            sub("^sd_ind__", "", grep("^sd_ind__", draw_names, value = TRUE)))
}