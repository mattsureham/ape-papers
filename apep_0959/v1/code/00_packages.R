## 00_packages.R — Load required packages
## apep_0959: Nursing Home Staffing Mandates and Care Quality

required_packages <- c(
  "data.table", "fixest", "did", "ggplot2",
  "modelsummary", "kableExtra", "jsonlite",
  "lubridate", "stringr"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
