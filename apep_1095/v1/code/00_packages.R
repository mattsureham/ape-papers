## 00_packages.R — Load required libraries
## apep_1095: Induced seismicity and self-regulation in Texas Permian Basin

required_packages <- c(
  "tidyverse",    # data wrangling + ggplot2
  "fixest",       # fast fixed effects (feglm for Poisson)
  "data.table",   # efficient data manipulation
  "jsonlite",     # JSON parsing (USGS API)
  "httr",         # HTTP requests
  "sf",           # spatial operations
  "modelsummary", # regression tables
  "kableExtra",   # table formatting
  "sandwich",     # robust SEs
  "MASS"          # glm.nb for negative binomial
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
