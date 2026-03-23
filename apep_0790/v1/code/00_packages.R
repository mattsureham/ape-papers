# 00_packages.R — Required packages for apep_0790
# The Air Quality Cost of Fireworks Deregulation

required <- c(
  "tidyverse",    # data manipulation + ggplot2
  "fixest",       # fast fixed effects
  "did",          # Callaway-Sant'Anna
  "data.table",   # efficient data reading
  "jsonlite",     # diagnostics output
  "xtable",       # LaTeX tables
  "httr",         # API calls
  "modelsummary"  # regression tables
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
