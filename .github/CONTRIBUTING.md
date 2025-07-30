# Contributing to LAVA

This outlines how to propose a change to LAVA.

## Fixing typos

You can fix typos, spelling mistakes, or grammatical errors in the documentation directly using the GitHub web interface, as long as the changes are made in the _source_ file.

## Bigger changes

If you want to make a bigger change, it's a good idea to first file an issue and make sure someone from the team agrees that it's needed.
If you've found a bug, please file an issue that illustrates the bug with a minimal 
[reprex](https://www.tidyverse.org/help/#reprex) (this will also help you write a unit test, if needed).

### Pull request process

*  Fork the package and clone onto your computer. If you haven't done this before, we recommend using `usethis::create_from_github("isadoo/LAVA", fork = TRUE)`.
*  Create a Git branch for your pull request (PR). We recommend using `usethis::pr_init("brief-description-of-change")`.
*  Make your changes, commit to git, and then create a PR with `usethis::pr_push()`.
*  The PR should include a title, a description, and a check on the package 
*  If you're not ready for the PR to be merged yet, [convert it to a draft PR](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/changing-the-stage-of-a-pull-request).

### Code style

*  New code should follow the tidyverse [style guide](https://style.tidyverse.org). 
*  Make sure to run `styler::style_pkg()` before submitting your PR.
*  We use [roxygen2](https://cran.r-project.org/package=roxygen2), with [Markdown syntax](https://cran.r-project.org/web/packages/roxygen2/vignettes/rd-formatting.html), for documentation.  
*  We use [testthat](https://cran.r-project.org/package=testthat) for unit tests. 
*  Contributions with test cases are easier to accept.  

## Code of Conduct

Please note that the LAVA project is released with a
[Contributor Code of Conduct](CODE_OF_CONDUCT.md). By contributing to this
project you agree to abide by its terms.
