## 00_packages.R — Load and install required packages
## APEP-0642 v2: Regulatory Whack-a-Mole

pkgs <- c(
  "tidyverse",    # data wrangling + ggplot2
  "fixest",       # fast FE estimation (feols)
  "data.table",   # memory-efficient data handling
  "modelsummary", # regression tables -> LaTeX
  "jsonlite",     # diagnostics.json output
  "httr",         # API/download
  "readr",        # fast CSV reading
  "lubridate",    # date parsing
  "did",          # Callaway-Sant'Anna staggered DiD
  "patchwork",    # multi-panel figure composition
  "scales"        # axis formatting for figures
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

# Fix masking: scales::pvalue masks fixest::pvalue
pvalue <- fixest::pvalue
se <- fixest::se

cat("All packages loaded.\n")
