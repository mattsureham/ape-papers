## 00_packages.R — Load and install required packages
## apep_0820: Gaussian Plume IV for Pollution and Test Scores

required_packages <- c(
  "tidyverse",   # data wrangling + ggplot2
  "fixest",      # fast fixed effects + IV
  "data.table",  # efficient data manipulation
  "httr",        # API calls
  "jsonlite",    # JSON parsing
  "geosphere",   # geodesic distance and bearing
  "readr",       # fast CSV reading
  "sf",          # spatial operations
  "modelsummary" # regression tables
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
