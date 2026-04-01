# =============================================================================
# 00_packages.R — Package loading for Korea short-selling ban analysis
# =============================================================================

required_packages <- c(
  "data.table", "fixest", "ggplot2", "sandwich", "lmtest",
  "xtable", "jsonlite", "dplyr", "tidyr", "stringr", "lubridate"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
