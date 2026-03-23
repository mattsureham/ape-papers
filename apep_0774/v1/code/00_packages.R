# 00_packages.R — Load required packages for apep_0774
# MSHA mine inspections and establishment-level employment

required_pkgs <- c(
  "data.table",    # Fast data manipulation
  "fixest",        # DiD/TWFE with clustered SEs
  "ggplot2",       # Internal QA plots
  "jsonlite",      # diagnostics.json
  "modelsummary",  # Table formatting
  "kableExtra"     # LaTeX tables
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  suppressPackageStartupMessages(library(pkg, character.only = TRUE))
}

cat("All packages loaded.\n")
