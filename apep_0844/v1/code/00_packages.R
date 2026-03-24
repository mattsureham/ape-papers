# 00_packages.R — Install and load required packages
# apep_0844: State Disinvestment and Enrollment Composition

pkgs <- c("data.table", "fixest", "ggplot2", "jsonlite", "ivreg",
          "httr", "readr", "dplyr", "tidyr", "stringr", "kableExtra",
          "modelsummary")

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
