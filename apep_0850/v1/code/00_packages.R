## 00_packages.R — apep_0850
## Cross-Border Workers and Minimum Wages: Geneva CHF 23/hr

pkgs <- c(
  "data.table", "fixest", "ggplot2", "dplyr", "tidyr", "readr",
  "stringr", "lubridate", "jsonlite", "sandwich", "lmtest",
  "did",        # Callaway & Sant'Anna
  "fwildclusterboot",  # Wild cluster bootstrap
  "modelsummary",      # Table output
  "kableExtra"         # LaTeX table formatting
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
