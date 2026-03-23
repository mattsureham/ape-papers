## ==========================================================================
## 00_packages.R — Load required packages
## Paper: Darkness by Decree (apep_0799)
## ==========================================================================

pkgs <- c(
  "data.table",    # Fast data manipulation
  "fixest",        # Fixed effects estimation
  "did",           # Callaway-Sant'Anna DiD estimator
  "ggplot2",       # Plotting (for diagnostics only)
  "modelsummary",  # Regression tables
  "kableExtra",    # LaTeX table formatting
  "sf",            # Spatial data
  "jsonlite",      # JSON for diagnostics
  "stringr",       # String operations
  "sandwich",      # Robust SEs
  "lmtest"         # Hypothesis tests
)

# Install missing packages
missing <- pkgs[!pkgs %in% rownames(installed.packages())]
if (length(missing) > 0) {
  cat("Installing:", paste(missing, collapse = ", "), "\n")
  install.packages(missing, repos = "https://cloud.r-project.org", quiet = TRUE)
}

# Load all
invisible(lapply(pkgs, library, character.only = TRUE))
cat("All packages loaded.\n")
