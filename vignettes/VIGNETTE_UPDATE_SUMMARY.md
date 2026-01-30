# Vignette Updates Summary

## What was done:
1. Updated vignette_tutorial.r to simplify the tutorial workflow
2. Added verbose parameter to calculate_coancestries()
3. Renamed var_pop/var_ind to V_AB/V_AW
4. Added summary.lava() method for concise output
5. Partially updated vignette_main.tex tutorial section

## What needs manual fixing in vignette_main.tex:

### Problem:
Lines 587-876 contain old/duplicate tutorial content that conflicts with the new Step 1-5 tutorial I added (lines 353-586).

### Solution:
Delete lines 587-876 (everything between the end of "Interpretation" subsection and the "Troubleshooting" section).

These lines contain:
- Duplicate/incomplete code fragments starting with "genotyped_parent_populations = pop,"
- Old Step 5-9 sections
- Old visualization and interpretation sections
- Batch processing examples

### Specific action:
In vignette_main.tex, after line 586 which ends with:
```
A positive log-ratio suggests that selection has caused greater differentiation between populations than drift alone would produce. The magnitude of the effect can be interpreted from the posterior distribution of the log-ratio.
```

Delete everything until you reach line 877:
```
\section{Troubleshooting}
```

This will leave you with a clean tutorial flow:
- Section 7 (Tutorial): Steps 1-5 with current best practices
- Section 8 (Troubleshooting): Existing troubleshooting content

### To verify your tutorial is complete, after running the script you should update:
1. The actual output values in head(dos[1:5,1:5]) and similar outputs
2. The actual summary(results) output values  
3. The actual head(results$sampling) output values showing V_AB and V_AW columns
4. Add the trait distribution plot figure if desired

### How to manually run the tutorial to get outputs:
```r
# In R/RStudio:
library(devtools)
load_all("/home/isa/github_repositories/LAVA")

# Then run the vignette_tutorial.r Part 2, or run interactively step by step
```

## Files created for your reference:
- `/home/isa/github_repositories/LAVA/vignettes/run_tutorial_only.r` - Simplified script
- `/home/isa/github_repositories/LAVA/vignettes/OUTPUTS_NEEDED_FOR_VIGNETTE.md` - Guide for what outputs to capture
- This summary file

## Next steps:
1. Manually delete lines 587-876 in vignette_main.tex
2. Run the tutorial script in R to get actual outputs
3. Update the placeholder values in the vignette with real outputs
4. Compile the PDF to verify it looks good
