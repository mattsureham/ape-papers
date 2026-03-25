## 00_packages.R — Load and install required packages
## apep_0897: The Carboniferous Lottery

pkgs <- c(
  "tidyverse",    # data wrangling + ggplot2

"fixest",       # feols, IV regression
  "data.table",   # fast data manipulation
  "httr",         # HTTP requests for APIs
  "jsonlite",     # JSON parsing
  "sf",           # spatial data
  "tidycensus",   # Census ACS data
  "janitor",      # clean names
  "sandwich",     # HAC standard errors
  "lmtest",       # coeftest
  "xtable",       # LaTeX table output
  "modelsummary", # regression tables
  "kableExtra",   # table formatting
  "stargazer"     # alternative tables
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
