# Load required packages
library(tidyverse)
library(data.table)
library(haven)  # For reading Stata files from WB
library(rlang)
library(jsonlite)
library(fixest)   # Modern DiD estimator
library(estimatr) # For robust SEs
library(writexl)  # For exporting to Excel

set.seed(20260407)  # Reproducibility

# Utility function: assert sample size
assert_sample_size <- function(df, n_min, label = "") {
  if (nrow(df) < n_min) {
    stop(paste0("Sample too small (", nrow(df), " < ", n_min, ") ", label))
  }
  invisible(df)
}

# Utility: cluster-robust SEs
get_robust_se <- function(model, cluster_var, data) {
  # Placeholder for robust SE extraction
  # Will be implemented with fixest::vcov
  model
}

# Directory structure
dir.create("../tables", showWarnings = FALSE)
dir.create("../data", showWarnings = FALSE)

cat("✓ Packages loaded\n")
