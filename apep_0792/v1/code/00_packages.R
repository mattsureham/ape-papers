## 00_packages.R — Load required packages
required <- c(
  "data.table", "fixest", "ggplot2", "httr", "jsonlite",
  "readr", "dplyr", "tidyr", "stringr", "sandwich", "lmtest"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
