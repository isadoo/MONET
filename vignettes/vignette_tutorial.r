
#This script is following the tutorial section of the vignette

#If you haven't imported yet:
devtools::install_github("isadoo/LAVA")
#Then make sure to update the libraries if necessary

library(LAVA)

#Loading Genetic data

neutral_file <- system.file("extdata", "neutral_data_g3000.dat", package = "LAVA")
quanti_file <- system.file("extdata", "quanti_trait_g3000.dat", package = "LAVA")

sim <- hierfstat::read.fstat(fname = neutral_file)
head(sim[,1:10])
# Pop n1_l1 n1_l2 n1_l3 n1_l4 n1_l5 n1_l6 n1_l7 n1_l8 n1_l9
# 1   1    22    11    21    11    22    11    11    22    11
# 2   1    22    11    11    11    21    11    12    22    11
# 3   1    22    11    22    11    22    22    11    22    11
# 4   1    22    11    11    11    11    21    12    22    11
# 5   1    22    11    11    11    11    11    11    22    11
# 6   1    22    11    11    11    21    11    11    22    11

sim_quanti <- hierfstat::read.fstat(fname = quanti_file)
# head(sim_quanti[,1:10])
#   Pop q1_l1 q1_l2 q1_l3 q1_l4 q1_l5 q1_l6 q1_l7 q1_l8 q1_l9
# 1   1    22    11    22    22    11    22    12    22    22
# 2   1    22    11    21    21    11    22    11    11    22
# 3   1    22    11    22    22    11    22    22    22    22
# 4   1    22    11    22    11    11    22    21    11    22
# 5   1    12    11    22    22    11    22    12    11    22
# 6   1    22    11    22    21    11    22    22    11    22

dos <- hierfstat::biall2dos(sim[, -1])
head(dos[,1:5])
#      n1_l1 n1_l2 n1_l3 n1_l4 n1_l5
# [1,]     2     0     1     0     2
# [2,]     2     0     0     0     1
# [3,]     2     0     2     0     2
# [4,]     2     0     0     0     0
# [5,]     2     0     0     0     0
# [6,]     2     0     0     0     1

dos_quanti <- hierfstat::biall2dos(sim_quanti[, -1])
head(dos_quanti[,1:5])
#      q1_l1 q1_l2 q1_l3 q1_l4 q1_l5
# [1,]     2     0     2     2     0
# [2,]     2     0     1     1     0
# [3,]     2     0     2     2     0
# [4,]     2     0     2     0     0
# [5,]     1     0     2     2     0
# [6,]     2     0     2     1     0

pop <- sim$Pop
dos_F1only_neutral <- readRDS(
  system.file("extdata", "vignette_dos_F1only_neutral.rds", package = "LAVA")
)

#Loading trait data
trait_df_pop <- read.csv(
  system.file("extdata", "vignette_trait_df_pop.csv", package = "LAVA")
)

head(trait_df_pop)
#   individual      trait trait_id population
# 1          1 -1.7629615        1          1
# 2          2 -1.6589637        1          1
# 3          3 -1.2060932        1          1
# 4          4 -0.1079098        1          1
# 5          5 -1.5611013        1          1
# 6          6 -1.1595368        1          1


population_individual_id_df <- read.csv(
  system.file("extdata", "vignette_population_individual_id_df.csv", 
              package = "LAVA")
)
head(population_individual_id_df)
#   pop_id individual
# 1      1        180
# 2      1        181
# 3      1        182
# 4      1        183
# 5      1        184
# 6      1        185

coancestries_dosage <- calculate_coancestries(
  genetic_data_parents = dos,
  genotyped_parent_populations = pop,
  genetic_data_F1 = dos_F1only_neutral, 
  population_individual_id = population_individual_id_df,
  column_individual = "individual", 
  column_population = "pop_id",
  all_parents_genotyped = TRUE
)
# When you run this function, it will print out some information on the subpopulations.
# This should yield a PD TheM and ThetaP matrices.
# The.M should have size 1000x1000.
# Theta.P should be 20 by 20. 

Theta.P <- coancestries_dosage$Theta.P
The.M <- coancestries_dosage$The.M

#Now we run LAVA
result <- lava(
  Theta.P = Theta.P,
  The.M = The.M,
  trait_dataframe = trait_df_pop,
  column_individual = "individual",
  column_trait = "trait"
)
#Once you run lava this is the output you should see:
# === Model Summary ===
#  Family: gaussian 
#   Links: mu = identity 
# Formula: Y ~ 1 + (1 | gr(pop, cov = two.Theta.P)) + (1 | gr(ind, cov = The.M)) 
#    Data: dat (Number of observations: 1000) 
#   Draws: 4 chains, each with iter = 5000; warmup = 2000; thin = 2;
#          total post-warmup draws = 6000

# Multilevel Hyperparameters:
# ~ind (Number of levels: 1000) 
#               Estimate Est.Error l-95% CI u-95% CI Rhat Bulk_ESS Tail_ESS
# sd(Intercept)     0.38      0.03     0.32     0.44 1.01      930     1540

# ~pop (Number of levels: 20) 
#               Estimate Est.Error l-95% CI u-95% CI Rhat Bulk_ESS Tail_ESS
# sd(Intercept)     0.80      0.17     0.55     1.19 1.00     3912     4923

# Regression Coefficients:
#           Estimate Est.Error l-95% CI u-95% CI Rhat Bulk_ESS Tail_ESS
# Intercept     0.07      0.41    -0.78     0.89 1.00     5326     4822

# Further Distributional Parameters:
#       Estimate Est.Error l-95% CI u-95% CI Rhat Bulk_ESS Tail_ESS
# sigma     0.31      0.02     0.28     0.35 1.01      955     1601

# Draws were sampled using sampling(NUTS). For each parameter, Bulk_ESS
# and Tail_ESS are effective sample size measures, and Rhat is the potential
# scale reduction factor on split chains (at convergence, Rhat = 1).

#If you want to check the convergence of your model you can do: 
#Convergence diagnostics
result$convergence
# $n_divergent
# [1] 0

# $max_rhat
# [1] 1.008571

#And to further examine the resutls you can use the following methods:
#full results
print(result)

#log-ratio statistics
result$log_ratio
# $p_value
# [1] 0
# 
# $mean_log_ratio
# [1] 0.7484329
# 
# $log_ratio_ci_lower
#      2.5% 
# 0.1329892 
# 
# $log_ratio_ci_upper
#     97.5% 
# 1.452598 
# 
# $median_log_ratio
#       50% 
# 0.7310082 
# 
# $ci_median_lower
#      2.5% 
# 0.1329892 
# 
# $ci_median_upper
#     97.5% 
# 1.452598

#Plot the posterior distribution of the log-ratio
plot(result)


#Because we did not change the parameter save_full_model to TRUE, the full brms model is not saved by default.
#Here we are looking at a sample of the posterior:
head(result$sampling)
#   b_Intercept sd_pop__Intercept sd_ind__Intercept var_pop var_ind log_ratio
#         <dbl>             <dbl>             <dbl>   <dbl>   <dbl>     <dbl>
# 1    -0.00658             0.752             0.410   0.566   0.168      1.22
# 2    -0.190               0.672             0.355   0.452   0.126      1.27
# 3     0.244               0.960             0.391   0.922   0.153      1.80
# 4     0.375               1.20              0.368   1.43    0.135      2.36
# 5    -0.200               0.686             0.363   0.471   0.132      1.27
# 6     0.399               0.835             0.366   0.697   0.134      1.65

#To extract the full brms model, you would need to run lava with save_full_model = TRUE, as shown below
result_full <- lava(
  Theta.P = Theta.P,
  The.M = The.M,
  trait_dataframe = trait_df_pop,
  column_individual = "individual",
  column_trait = "trait",
  save_full_model = TRUE  # This saves the complete brms model
)

result_full$sampling  # This is now a brmsfit object