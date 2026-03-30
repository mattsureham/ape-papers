# 00_packages.R — Load required packages for PTZ bunching analysis
# apep_1173

pkgs <- c("data.table", "fixest", "jsonlite", "xtable")

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
