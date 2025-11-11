#' @title lava: Log ratios of ancestral variances
#'
#' @description Given coancestry matrices for between and within populations and a trait data frame, 
#' this function estimates the log ratio of ancestral variances using a Bayesian mixed-effects model.
#' 
#' @usage lava(Theta.P, The.M, trait_dataframe, column_individual = "id", column_trait = "trait", 
#'             column_population = "population", formula_covariates = NULL, ...)
#'
#' @param Theta.P A square matrix representing the coancestry matrix between populations.
#'
#' @param The.M A square matrix representing the kinship-based relatedness matrix for individuals.
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
#' 
#' @param ... Additional arguments passed to the brms function.
#'
#' @return A lava type object containing:
#' \item{posterior_samples}{A list with posterior samples of variance components and residuals.}
#' \item{log_ratio}{A list with the p-value of the log ratios, the mean of the log ratio of between- and within-population variance, and confidence intervals.}
#' \item{model}{as an attribute.}
#' 
#' @details This function standardizes trait data, constructs a Bayesian mixed-effects model 
#' using `brms`, and estimates ancestral variances. The function assumes no crosses between populations 
#' and analyzes one trait at a time.
#'
#' @author Isabela do O \email{isabela.doo@@unil.ch}
#'
#' @references 
#' 
#' - Goudet & Weir (2023)
#' - do O et al (2025)
#'
#' @export
lava <- function(Theta.P, 
                 The.M, 
                 trait_dataframe, 
                 column_individual = "id", 
                 column_trait = "trait", 
                 column_population = "population",
                 column_se = NULL,
                 formula_covariates = NULL,
                 iter = 5000, warmup = 2000, thin = 2,
                 save_full_model = FALSE,
                 ...) {
  
  #check input types and dimensions ------------------------
  if (!is.matrix(Theta.P) || !is.matrix(The.M)) {
    stop("Theta.P and The.M must be matrices.")
  }
  
  if (!is.data.frame(trait_dataframe) || ncol(trait_dataframe) < 2) {
    stop("trait_dataframe must be a data frame with at least two columns (ID and trait values).")
  }
  #------------------------------------------------------------
  
  #extract columns by name if provided ------------------------------------
  id_col <- if(is.numeric(column_individual)) column_individual else which(names(trait_dataframe) == column_individual)
  trait_col <- if(is.numeric(column_trait)) column_trait else which(names(trait_dataframe) == column_trait)
  
  #Identify populations per individual
  population_blocks_df <- counting_blocks_matrix(The.M) #this function counts the number of blocks of non-zero rows in a matrix
  individuals_per_population_F1 <- population_blocks_df$rows
  number_of_blocks <- length(population_blocks_df$block) 
  pop_ids <- rep(1:number_of_blocks, individuals_per_population_F1[1:number_of_blocks]) 
  number_populations <- nrow(Theta.P)
  
  if (number_of_blocks != number_populations & !(column_population %in% names(trait_dataframe))) {
    warning(paste0("Mismatch between detected groups based on The.M matrix (", number_of_blocks,") and populations in Theta.P dimensions (", number_populations, ")\n
                   We have have no way of knowing what is the correct number of individuals in each subpopulation."))
  }
  
  Y <- trait_dataframe[,trait_col]
  
  if (is.list(Y)) {
    Y <- unlist(Y)
  }
  
  #Ensure Y is numeric
  Y <- as.numeric(Y)
  
  #remove any NAs
  valid_indices <- !is.na(Y)
  Y <- Y[valid_indices]
  
  #Filter the dataframe to match
  trait_dataframe <- trait_dataframe[valid_indices, ]
  
  # Standardize
  Y <- Y - mean(Y)
  var_Y <- var(Y)
  Y <- Y / sqrt(var_Y)
  
  have_se <- !is.null(column_se) && (column_se %in% names(trait_dataframe))
  #Incorportate measurment errors (se) if provided
  if (have_se) {
    Y_se <- trait_dataframe[[column_se]] / sqrt(var_Y)
  }


  #From VB = VA*2FST
  two.Theta.P <- 2 * Theta.P
  
  pop_col <- if(column_population %in% names(trait_dataframe)) {
    trait_dataframe[,column_population]
  } else {
    paste0("pop_", pop_ids)  # fallback to generated pop labels
  }
  
  if (is.list(pop_col)) {
    pop_col <- unlist(pop_col)
  }
  pop_col <- as.character(pop_col)
  
  ind_col <- trait_dataframe[,id_col]
  if (is.list(ind_col)) {
    ind_col <- unlist(ind_col)
  }
  ind_col <- as.character(ind_col)

  #Build the data frame
  dat <- data.frame(pop = pop_col, ind = ind_col, Y = Y)
  if (have_se) dat$Y_se <- Y_se

  # Add any additional covariates that might be specified
  if (!is.null(formula_covariates)) {
    # Extract covariate names from formula_covariates
    covariate_names <- trimws(unlist(strsplit(formula_covariates, "\\+")))
    
    # Add covariates to the data frame if they exist in trait_dataframe
    for (cov_name in covariate_names) {
      if (cov_name %in% names(trait_dataframe)) {
        cov_data <- trait_dataframe[,cov_name]
        if (is.list(cov_data)) {
          cov_data <- unlist(cov_data)
        }
        dat[[cov_name]] <- cov_data
      } else {
        warning(paste("Covariate", cov_name, "not found in trait_dataframe"))
      }
    }
  }
  
  #Build the complete formula
  base_formula <- "Y ~ 1 + (1 | gr(pop, cov = two.Theta.P)) + (1 | gr(ind, cov = The.M))"
  base_rhs <- "(1 | gr(pop, cov = two.Theta.P)) + (1 | gr(ind, cov = The.M))"
  rhs <- if (is.null(formula_covariates)) base_rhs else paste0(formula_covariates, " + ", base_rhs)

  if (have_se) {
    # Use measurement error on the response; still estimate residual sigma
    model_formula <- brms::bf(as.formula(paste0("Y | se(Y_se, sigma = TRUE) ~ 1 + ", rhs)))
    cat("Measurement SE column: ", column_se, " (scaled to standardized Y)\n", sep = "")
  } else {
    model_formula <- as.formula(paste0("Y ~ 1 + ", rhs))
  }

  if (!is.null(formula_covariates)) {
    formula_string <- paste0("Y ~ 1 + ", formula_covariates, " + (1 | gr(pop, cov = two.Theta.P)) + (1 | gr(ind, cov = The.M))")
  } else {
    formula_string <- base_formula
  }
  
  model_formula <- as.formula(formula_string)
  
  cat("Using formula:", formula_string, "\n")
  
  #Diagnostics
  n_total <- nrow(dat)
  n_complete <- sum(complete.cases(dat))
  cat("Total rows:", n_total, " ; complete rows used:", n_complete, "\n")
  
  #check for NAs
  na_counts <- colSums(is.na(dat))
  if (any(na_counts > 0)) {
    cat("Warning: NAs found in columns:\n")
    print(na_counts[na_counts > 0])
  }
  
  
  #Bayesian model - using brms package
  #Use tryCatch to handle convergence issues gracefully
  brms_mf <- tryCatch({
    brm(
      formula = model_formula,
      data = dat,
      data2 = list(two.Theta.P = two.Theta.P, The.M = The.M), 
      iter = iter, warmup = warmup, thin = thin,
      ...
    )

  }, error = function(e) {
    cat("Error fitting model:", e$message, "\n")
    stop(e)
  })
  
  # Print summary properly
  cat("\n=== Model Summary ===\n")
  print(summary(brms_mf))
  cat("\n")
  
  # Check for convergence issues
  rhats <- rhat(brms_mf)
  if (any(rhats > 1.01, na.rm = TRUE)) {
    warning("Some Rhat values > 1.01, indicating potential convergence issues")
  }
  
  # Check for divergent transitions
  sampler_params <- nuts_params(brms_mf)
  n_divergent <- sum(sampler_params$divergent__)
  if (n_divergent > 0) {
    warning(paste("Model had", n_divergent, "divergent transitions after warmup"))
  }
  
  #variance components
  var_components <- lapply(VarCorr(brms_mf, summary = FALSE), function(x) x$sd^2)
  var_df <- as.data.frame(do.call(cbind, var_components))

  hyp <- "sd_pop__Intercept^2 - sd_ind__Intercept^2 = 0"
  the_hyp <- hypothesis(brms_mf, hyp, class = NULL)

  # --- core draws we need ---
  # Get all draws once, then select columns we care about depending on save_full_model
  all_draws <- posterior::as_draws_df(brms_mf)

fe_cols <- grep("^b_", names(all_draws), value = TRUE)     # fixed effects
sd_cols <- c("sd_pop__Intercept", "sd_ind__Intercept")     # two RE SDs

have_sd <- sd_cols[sd_cols %in% names(all_draws)]

if (length(have_sd) == 2) {
  minimal_samples <- all_draws[, unique(c(fe_cols, have_sd)), drop = FALSE]
  minimal_samples$var_pop  <- minimal_samples$sd_pop__Intercept^2
  minimal_samples$var_ind  <- minimal_samples$sd_ind__Intercept^2
  minimal_samples$log_ratio <- log(minimal_samples$var_pop / minimal_samples$var_ind)
} else {
  warning("Issue with your model - to use lava you should get a sd_pop__Intercept and sd_ind__Intercept in draws in order to have a log-ratio; minimal samples include only fixed effects.")
}

  # For summary stats below we still use post_samples with log_ratio
  post_samples <- minimal_samples

  # --- summaries of log-ratio ---
  if ("log_ratio" %in% names(post_samples)) {
    quant_log_med   <- stats::quantile(post_samples$log_ratio, c(0.5, 0.025, 0.975))
    mean_log_ratio  <- mean(post_samples$log_ratio)
    quant_log_ratio <- stats::quantile(post_samples$log_ratio, probs = c(0.025, 0.975))
    p_value <- 2 * mean(sign(post_samples$log_ratio) != sign(stats::median(post_samples$log_ratio)))
  } else {
    warning("No log_ratio samples found - cannot compute log-ratio summaries.")
  }

  # ----------------------------
      # preparing results object #
  # ----------------------------
  results <- list(
  sampling = if (isTRUE(save_full_model)) {
    # Return the full brms model as 'sampling'
    brms_mf
  } else {
    # Minimal sampling: fixed effects + two RE SDs + var_* + log_ratio
    minimal_samples
  },

  log_ratio = list(
    p_value = p_value,
    mean_log_ratio = mean_log_ratio,
    log_ratio_ci_lower = quant_log_ratio[1],
    log_ratio_ci_upper = quant_log_ratio[2],
    median_log_ratio = quant_log_med["50%"],
    ci_median_lower = quant_log_med["2.5%"],
    ci_median_upper = quant_log_med["97.5%"]
  ),

  hypothesis = the_hyp$hypothesis[2:5],
  trait_name = names(trait_dataframe)[trait_col],
  formula_used = formula_string,
  convergence = list(
    n_divergent = n_divergent,
    max_rhat = max(rhats, na.rm = TRUE)
  )
)
class(results) <- "lava"
return(results)
}
#' @export
plot.lava <- function(x, ...) {
  # Accept either a brmsfit (full model) or a draws data.frame in x$sampling
  if (inherits(x$sampling, "brmsfit")) {
    # compute log_ratio from the model draws
    draws <- posterior::as_draws_df(x$sampling)
    if (!all(c("sd_pop__Intercept", "sd_ind__Intercept") %in% names(draws))) {
      stop("Could not find sd_pop__Intercept/sd_ind__Intercept in model draws to compute log_ratio.")
    }
    lr <- log((draws$sd_pop__Intercept^2) / (draws$sd_ind__Intercept^2))
  } else {
    samp <- x$sampling
    if (is.null(samp) || !"log_ratio" %in% names(samp)) {
      stop("No 'log_ratio' samples found. Refit or set save_full_model=TRUE so draws are available.")
    }
    lr <- samp$log_ratio
  }

  med <- stats::median(lr)
  ci  <- stats::quantile(lr, c(0.025, 0.975))

  
  d <- stats::density(lr)
  plot(d, main = "Posterior of log-ratio",
    xlab = "log(Var_between / Var_within)", ylab = "Posterior density")
    abline(v = med, lty = 2)
    abline(v = ci, lty = 3)
    legend("topright",
        legend = c(paste0("median = ", round(med, 3)),
                    paste0("95% CI [", round(ci[1], 3), ", ", round(ci[2], 3), "]")),
        lty = c(2, 3), bty = "n")

  invisible(NULL)
}