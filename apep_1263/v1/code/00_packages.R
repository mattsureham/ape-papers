## 00_packages.R — Load required packages
## apep_1263: The Opt-Out Illusion

pkgs <- c("data.table", "fixest", "ggplot2", "modelsummary",
          "kableExtra", "jsonlite")

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
