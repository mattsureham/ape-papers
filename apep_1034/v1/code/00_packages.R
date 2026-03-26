## 00_packages.R — Install and load required packages
## apep_1034: Norway Wind Resource Rent Tax

required_packages <- c(
  "tidyverse",    # data manipulation + ggplot2
  "fixest",       # fast fixed effects estimation
  "httr",         # HTTP requests for SSB API
  "jsonlite",     # JSON parsing
  "sandwich",     # robust covariance estimators
  "lmtest",       # coefficient tests
  "fwildclusterboot", # wild cluster bootstrap for small clusters
  "modelsummary", # regression tables
  "kableExtra"    # table formatting
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
