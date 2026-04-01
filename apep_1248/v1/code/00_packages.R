## 00_packages.R — Install and load required packages for apep_1248

pkgs <- c(
  "tidyverse",    # data wrangling + ggplot2

"fixest",       # fast fixed effects
  "data.table",   # fast data reading
  "haven",        # read .dta/.sav files
  "jsonlite",     # write diagnostics.json
  "modelsummary", # regression tables
  "kableExtra",   # table formatting
  "sandwich",     # robust SEs
  "lmtest"        # coeftest
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
