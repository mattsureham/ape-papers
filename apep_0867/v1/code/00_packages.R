## 00_packages.R — Load and install required packages
## apep_0867: Upload Filters and the Creative Economy

required <- c(
  "tidyverse", "fixest", "did", "eurostat",
  "jsonlite", "httr", "sandwich", "lmtest",
  "HonestDiD", "kableExtra"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
