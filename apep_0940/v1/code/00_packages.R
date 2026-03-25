## 00_packages.R — Load required packages for apep_0940
## Denmark Parallel Society Designation and Displacement

required_packages <- c(
  "data.table",
  "fixest",
  "did",           # Callaway-Sant'Anna
  "httr",
  "jsonlite",
  "ggplot2",
  "modelsummary",
  "kableExtra",
  "sandwich",
  "HonestDiD"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
