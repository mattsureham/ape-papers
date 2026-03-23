# 00_packages.R — Load required packages for Swiss NFA reform analysis
# apep_0813/v1

pkgs <- c("httr", "jsonlite", "data.table", "fixest", "xtable", "sandwich")
for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

# Check for fwildclusterboot (needed for wild cluster bootstrap with 26 cantons)
if (!requireNamespace("fwildclusterboot", quietly = TRUE)) {
  install.packages("fwildclusterboot", repos = "https://cloud.r-project.org")
}
library(fwildclusterboot)

cat("All packages loaded successfully.\n")
