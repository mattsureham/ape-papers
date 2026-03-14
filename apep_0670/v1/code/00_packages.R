## 00_packages.R — Install and load required packages
## apep_0670: Comment Period Length and Public Participation

pkgs <- c(
  "tidyverse",    # data manipulation and visualization
  "fixest",       # fixed effects estimation
  "httr2",        # HTTP API requests
  "jsonlite",     # JSON parsing
  "modelsummary", # regression tables
  "kableExtra",   # table formatting
  "rdrobust",     # RD estimation
  "sandwich",     # robust SEs
  "lmtest"        # coefficient tests
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
