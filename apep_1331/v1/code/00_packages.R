## 00_packages.R — Load and install required packages
## APEP apep_1331: Free Tuition and Philippine Higher Education

required <- c(
  "tidyverse",    # data wrangling + ggplot2
  "fixest",       # TWFE with clustered SEs
  "WDI",          # World Bank Development Indicators API
  "httr",         # HTTP requests (UNESCO UIS API)
  "jsonlite",     # JSON parsing
  "sandwich",     # robust SEs
  "lmtest",       # coefficient tests
  "clubSandwich",     # cluster-robust SEs for few clusters
  "modelsummary", # regression tables
  "kableExtra"    # LaTeX table formatting
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
