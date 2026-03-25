# 00_packages.R — Load and install required packages
# apep_0842: The Safe Country Lottery

required_packages <- c(
  "tidyverse",    # data manipulation and visualization
  "fixest",       # high-dimensional fixed effects
  "eurostat",     # Eurostat data API
  "data.table",   # efficient data operations
  "jsonlite",     # diagnostics output
  "xtable",       # LaTeX tables
  "sandwich",     # robust standard errors
  "lmtest",       # coefficient tests
  "did",          # Callaway-Sant'Anna staggered DiD
  "latex2exp"     # LaTeX expressions in ggplot
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
