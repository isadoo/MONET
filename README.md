---
output: github_document
---

<!-- README.md is generated from README.Rmd. Please edit that file -->



# LAVA <img src="man/figures/logo.png" align="right" height="139" alt="" />

<!-- badges: start -->
[![R-CMD-check](https://github.com/isadoo/LAVA/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/isadoo/LAVA/actions/workflows/R-CMD-check.yaml)
[![Codecov test coverage](https://codecov.io/gh/isadoo/LAVA/branch/master/graph/badge.svg)](https://app.codecov.io/gh/isadoo/LAVA?branch=master)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![CRAN status](https://www.r-pkg.org/badges/version/LAVA)](https://CRAN.R-project.org/package=LAVA)
[![CRAN RStudio mirror downloads](https://cranlogs.r-pkg.org/badges/grand-total/LAVA)](https://r-pkg.org/pkg/LAVA)
[![GitHub last commit](https://img.shields.io/github/last-commit/isadoo/LAVA.svg)](https://github.com/isadoo/LAVA/commits/master)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.placeholder.svg)](https://doi.org/10.5281/zenodo.placeholder)
[![Citation Status](https://img.shields.io/badge/cited%20by-0%20publications-4D76C9)](https://scholar.google.com/scholar?q=LAVA+package+R)
[![GitHub release date](https://img.shields.io/github/release-date/isadoo/LAVA.svg)](https://github.com/isadoo/LAVA/releases)
[![GitHub release](https://img.shields.io/github/release/isadoo/LAVA.svg)](https://github.com/isadoo/LAVA/releases)
[![Dependencies](https://img.shields.io/badge/dependencies-up%20to%20date-brightgreen)](https://github.com/isadoo/LAVA/blob/master/DESCRIPTION)
[![Project Status: WIP](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)
[![r-universe](https://isadoo.r-universe.dev/badges/LAVA)](https://isadoo.r-universe.dev)
[![minimal R version](https://img.shields.io/badge/R%3E%3D-3.5-6666ff.svg)](https://cran.r-project.org/)
<!-- badges: end -->

> **⚠️ WORK IN PROGRESS**  
> LAVA is currently under development. The package is public and available for testing, but please be aware that:
> - Features and functions may change;
> - Documentation is being improved;
> - We are still testing the functions and usage;
> - Breaking changes may occur in future versions.
> 
> We welcome feedback! Please report any issues on our [GitHub Issues page](https://github.com/isadoo/LAVA/issues), or if you have questions please reach out to isabela[dot]doo[at]unil[dot]ch

## Overview

LAVA (Log ratio of Ancestral Variances) is an R package designed to help researchers analyze quantitative trait data in order to test for local adaptation following the method LogAV. We do that by comparing estimates of ancestral variances. The package provides tools for statistical analysis for identifying local adaptation.

## Installation

You can install the development version of LAVA from GitHub:

### For Contributors and Collaborators with GitHub Access
The easiest way to install LAVA is:

```r
# Install devtools if you haven't already
install.packages("devtools")

# Install LAVA
devtools::install_github("isadoo/LAVA")
```

### Dependencies

LAVA requires the following packages, which will be installed automatically:
- `kinship2` - for kinship calculations
- `hierfstat` - for hierarchical F-statistics
- `brms` - for Bayesian regression models
- `JGTeach` - for population genetics utilities
- `gaston` - for genetic data manipulation
- `Matrix` - for efficient matrix operations
- `dplyr`, `tidyr`, `magrittr` - for data manipulation

### For Contributors: Development Installation
If you want to work on the development of LAVA, you may want to clone the repository and install locally:

```r
# Clone the repository first (in your terminal)
# git clone https://github.com/isadoo/LAVA.git
# cd LAVA

# Then in R, install with dependencies
devtools::install(".", dependencies = TRUE)
```

## Example (needs to be updated)

This is a basic example which shows you how to use LAVA:


```r
library(LAVA)
coancestries <- calculate_coancestries(genetic_data_parents = dos_Founders,
                                              genotyped_parent_populations = pop,
                                              genetic_data_F1 = dos_F1, 
                                              population_individual_id = population_individual_id_df,
                                              column_individual = "individual", 
                                              column_population = "pop_id")
results <- lava(Theta.P, 
                M, 
                trait_dataframe = trait_df_pop, 
                column_individual = "individual", 
                column_trait = "trait")

```

## Features

The LAVA package provides:

- Analysis tools for estimated variance comparison
- Coancestry matrix calculator

## Documentation

For more detailed information, please check ...?.

## Contributing

As the package is still experimental, please reach out via our [GitHub Issues page](https://github.com/isadoo/LAVA/issues) if you'd like to contribute

## Getting Help

- For bug reports and feature requests, please use the [GitHub Issues page](https://github.com/isadoo/LAVA/issues)
- For questions about usage, feel free to contact isabela.doo@unil.ch

## Citation
If you use LAVA in your research, please cite:
[add citation for the two papers]

## Acknowledgments

LAVA relies heavily on several key R packages:

- **`brms`** for Bayesian regression modeling - for the section using linear mixed model we follow a lot of their default values - we highly recommend users familiarize themselves with its [documentation](https://paul-buerkner.github.io/brms/)
- **`hierfstat`** for hierarchical F-statistics and genetic data analysis - see its [CRAN page](https://CRAN.R-project.org/package=hierfstat) for details
- **`kinship2`** for kinship calculations - see [KINSHIP2_MIGRATION.md](KINSHIP2_MIGRATION.md) for details on our implementation.
