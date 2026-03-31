## 00_packages.R — Load and install required packages
## apep_1179: Anti-corruption enforcement and fiscal composition in China

pkgs <- c(
  "tidyverse",    # data wrangling + ggplot2
  "fixest",       # TWFE + Sun-Abraham event studies
  "did",          # Callaway-Sant'Anna estimator
  "haven",        # read Stata .dta files
  "data.table",   # fast data manipulation
  "modelsummary", # regression tables
  "kableExtra",   # table formatting
  "jsonlite"      # write diagnostics.json
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
