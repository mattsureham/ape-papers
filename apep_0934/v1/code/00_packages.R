# 00_packages.R — Package installation and loading for apep_0934
# Community wind ownership and NIMBYism in Denmark

required_packages <- c(
  "httr", "jsonlite", "readxl", "dplyr", "tidyr", "stringr",
  "fixest", "did", "HonestDiD", "sandwich", "lmtest",
  "ggplot2", "modelsummary", "kableExtra",
  "data.table", "lubridate"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
