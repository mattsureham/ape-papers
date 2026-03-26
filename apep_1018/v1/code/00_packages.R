## 00_packages.R — apep_1018: NK Exodus and Armenian Labor Markets
## Install and load required packages

pkgs <- c(
  "tidyverse",    # data wrangling + ggplot2

  "fixest",       # fast fixed effects (feols, sunab)
  "data.table",   # efficient data manipulation
  "jsonlite",     # JSON I/O
  "httr",         # API calls
  "sandwich",     # robust SEs
  "lmtest",       # coefficient tests
  "fwildclusterboot",  # wild cluster bootstrap (few clusters)
  "modelsummary", # regression tables
  "kableExtra",   # table formatting
  "xtable"        # LaTeX tables
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
