# 00_packages.R — Load required libraries for apep_1333
# CA Marine Protected Areas and Kelp Forest Fish Assemblages

packages <- c(
  "data.table", "fixest", "did", "ggplot2", "dplyr", "tidyr",
  "readr", "stringr", "jsonlite", "xtable", "sandwich", "lmtest",
  "HonestDiD", "here"
)

for (pkg in packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
