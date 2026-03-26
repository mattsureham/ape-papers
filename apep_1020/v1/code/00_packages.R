# 00_packages.R — Package dependencies for SDLT bunching migration paper
# apep_1020/v1

required_packages <- c(
  "data.table",    # Fast data manipulation
  "fixest",        # Fixed effects estimation
  "ggplot2",       # Plotting (for internal QA only, no figures in V1)
  "xtable",        # LaTeX table generation
  "jsonlite",      # diagnostics.json output
  "curl",          # Data download
  "stringr",       # String manipulation
  "zoo"            # Rolling window operations
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
