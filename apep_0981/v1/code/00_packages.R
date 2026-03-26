## 00_packages.R — Install and load required packages
## apep_0981: Good Samaritan Laws and Opioid Treatment Admissions

required_packages <- c(
  "tidyverse",    # data manipulation + ggplot2

  "fixest",       # fast fixed effects (TWFE diagnostics)
  "did",          # Callaway-Sant'Anna staggered DiD
  "data.table",   # efficient data handling
  "haven",        # read SAS/SPSS files
  "jsonlite",     # write diagnostics.json
  "httr",         # API calls
  "xtable",       # LaTeX tables
  "knitr",        # table formatting
  "readr"         # CSV reading
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
