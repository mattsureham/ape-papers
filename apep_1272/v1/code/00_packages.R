## 00_packages.R — Load and install required packages
## apep_1272: Breaking the Gauge Barrier

pkgs <- c("data.table", "fixest", "jsonlite", "ggplot2", "sf",
          "did", "modelsummary", "kableExtra")

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
