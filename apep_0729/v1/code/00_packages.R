## 00_packages.R — Required packages for apep_0729
## Press subsidies and voter turnout in Norway

pkgs <- c(
  "jsonlite",      # SSB API JSON-stat parsing
  "data.table",    # Fast data manipulation
  "fixest",        # Fixed effects estimation
  "readxl",        # Excel file reading
  "modelsummary",  # Regression tables
  "kableExtra",    # LaTeX table formatting
  "xtable"         # Additional table output
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
