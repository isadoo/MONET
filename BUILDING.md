# Building and Checking the LAVA Package

This document provides step-by-step instructions for building, checking, and installing the LAVA package.

## Prerequisites

Make sure you have the following R packages installed:

```r
install.packages(c("devtools", "roxygen2", "testthat", "knitr", "rmarkdown", "covr", "pkgdown"))
```

## Workflow for Package Development

### 1. Documenting the Package

Generate documentation from roxygen comments:

```r
devtools::document()
```

### 2. Testing the Package

Run tests to ensure everything works as expected:

```r
devtools::test()
```

Check test coverage:

```r
covr::package_coverage()
```

### 3. Building the Package

Build the package:

```r
devtools::build()
```

### 4. Checking the Package

Run a comprehensive check of the package:

```r
devtools::check()
```

For a CRAN submission check:

```r
devtools::check(cran = TRUE)
```

### 5. Installing the Package

Install the package locally:

```r
devtools::install()
```

### 6. Building the Documentation Website

Build the pkgdown site:

```r
pkgdown::build_site()
```

## GitHub Actions Workflow

The package uses GitHub Actions for continuous integration:

1. Automatic R CMD check on multiple platforms
2. Code coverage reporting through Codecov
3. pkgdown site deployment to GitHub Pages

When you push changes to the master branch, these actions run automatically.

## Common Issues and Solutions

### Package Dependencies

If you need to add a package dependency:

```r
usethis::use_package("packagename")
```

### Documentation Issues

If roxygen2 documentation doesn't generate correctly, check:
- Are roxygen comments formatted correctly?
- Are all exported functions documented?
- Are all parameters documented?

### Testing Issues

If tests fail:
- Check that test expectations match function behavior
- Ensure all dependencies are properly listed
- Check for environment-specific issues

## Releasing to GitHub

1. Update version number in DESCRIPTION
2. Update NEWS.md with changes
3. Run all checks and tests
4. Commit and push changes
5. Create a new release on GitHub

## References and Resources

- [R Packages (2e) by Hadley Wickham and Jenny Bryan](https://r-pkgs.org/)
- [roxygen2 documentation](https://roxygen2.r-lib.org/)
- [testthat documentation](https://testthat.r-lib.org/)
- [pkgdown documentation](https://pkgdown.r-lib.org/)
