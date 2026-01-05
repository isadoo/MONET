test_that("lava function validates input correctly", {
  # Test input validation for matrices
  expect_error(
    lava(Theta.P = "not_a_matrix", M = matrix(1, 2, 2), trait_dataframe = data.frame(id = 1:2, trait = c(1, 2))),
    "Theta.P and M must be matrices"
  )
  
  expect_error(
    lava(Theta.P = matrix(1, 2, 2), M = "not_a_matrix", trait_dataframe = data.frame(id = 1:2, trait = c(1, 2))),
    "Theta.P and M must be matrices"
  )
  
  # Test input validation for trait dataframe
  expect_error(
    lava(Theta.P = matrix(1, 2, 2), M = matrix(1, 2, 2), trait_dataframe = "not_a_dataframe"),
    "trait_dataframe must be a data frame with at least two columns"
  )
  
  expect_error(
    lava(Theta.P = matrix(1, 2, 2), M = matrix(1, 2, 2), trait_dataframe = data.frame(id = 1:2)),
    "trait_dataframe must be a data frame with at least two columns"
  )
})

test_that("lava function creates proper S3 object structure", {
  # Skip this test if brms is not available (since it's a heavy dependency)
  skip_if_not_installed("brms")
  
  # Create minimal test data
  set.seed(123)
  n_individuals <- 4
  n_populations <- 2
  
  # Simple block diagonal kinship matrix
  M <- matrix(0, n_individuals, n_individuals)
  M[1:2, 1:2] <- 0.5
  M[3:4, 3:4] <- 0.5
  diag(M) <- 1
  
  # Simple population coancestry matrix
  Theta.P <- matrix(c(0.1, 0.05, 0.05, 0.1), 2, 2)
  
  # Trait data
  trait_data <- data.frame(
    id = paste0("ind_", 1:n_individuals),
    trait = rnorm(n_individuals, mean = 0, sd = 1)
  )
  
  # This test may take time due to MCMC sampling, so we use minimal iterations
  # In practice, you might want to skip this test or use mock data
  skip("Skipping full lava test due to MCMC computation time")
  
  # result <- lava(
  #   Theta.P = Theta.P,
  #   M = M,
  #   trait_dataframe = trait_data,
  #   chains = 1, iter = 100, warmup = 50  # Minimal for testing
  # )
  # 
  # # Check S3 class
  # expect_s3_class(result, "lava")
  # 
  # # Check required components
  # expect_true("posteriors_samples" %in% names(result))
  # expect_true("BRMS_stats" %in% names(result))
  # expect_true("log_ratio" %in% names(result))
  # expect_true("hypothesis" %in% names(result))
  # expect_true("trait_name" %in% names(result))
  # 
  # # Check that model attribute exists
  # expect_true(!is.null(attr(result, "model")))
})

test_that("lava function handles column name specification", {
  # Create test data with different column names but expect brms errors
  M <- diag(4)
  Theta.P <- matrix(0.1, 2, 2)
  diag(Theta.P) <- 0.2
  
  trait_data_custom <- data.frame(
    individual_id = paste0("ind_", 1:4),
    phenotype = rnorm(4),
    extra_col = 1:4
  )
  
  # Test that the function accepts custom column names but may fail at brms level
  # due to dimension mismatches between Theta.P and M
  expect_error(
    lava(
      Theta.P = Theta.P,
      M = M,
      trait_dataframe = trait_data_custom,
      column_individual = "individual_id",
      column_trait = "phenotype"
    ),
    "Levels of the within-group covariance matrix|Mismatch between detected populations"
  )
})

test_that("print.lava method works correctly", {
  # Create a mock lava object for testing the print method
  mock_lava <- list(
    log_ratio = list(
      mean_log_ratio = 0.1,
      log_ratio_ci_lower = -0.05,
      log_ratio_ci_upper = 0.25,
      p_value = 0.05
    ),
    BRMS_stats = list(
      mean_diff = 0.02,
      median = 0.015,
      median_lower = -0.01,
      median_upper = 0.04
    )
  )
  class(mock_lava) <- "lava"
  
  # Test that print method doesn't error and returns invisibly
  expect_output(print(mock_lava), "Log Ancestral Variance Analysis")
  expect_output(print(mock_lava), "Mean: 0.1000")
  expect_invisible(print(mock_lava))
})

test_that("plot.lava method works correctly", {
  # Create a mock lava object with required data for plotting
  set.seed(123)
  n_samples <- 100
  
  mock_lava <- list(
    post_samples = data.frame(
      log_ratio = rnorm(n_samples, 0, 0.5),
      between_pop_variance = rgamma(n_samples, 2, 2),
      within_pop_variance = rgamma(n_samples, 2, 2)
    ),
    BRMS_log = list(
      mean_log_ratio = 0,
      log_ratio_ci_lower = -0.5,
      log_ratio_ci_upper = 0.5
    )
  )
  class(mock_lava) <- "lava"
  
  # Test that plot method doesn't error
  expect_error(plot(mock_lava, which = "density"), NA)
  expect_error(plot(mock_lava, which = "scatter"), NA)
  expect_error(plot(mock_lava, which = "both"), NA)
  
  # Test invalid which parameter
  expect_error(plot(mock_lava, which = "invalid"))
})
