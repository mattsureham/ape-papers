## 00_packages.R — Load and install required packages
required <- c(
  "data.table", "fixest", "did", "ggplot2", "httr", "jsonlite",
  "readr", "dplyr", "tidyr", "stringr", "xtable", "kableExtra",
  "sandwich", "lmtest"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
