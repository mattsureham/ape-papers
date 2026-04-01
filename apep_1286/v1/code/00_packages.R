# 00_packages.R — Required packages for Alice Corp analysis
# Install if needed, then load

pkgs <- c("data.table", "fixest", "ggplot2", "dplyr", "tidyr", "readr",
          "jsonlite", "xtable", "kableExtra", "modelsummary", "broom")

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
