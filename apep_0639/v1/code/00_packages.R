# 00_packages.R — Load and install required packages
# apep_0639: Opioid Day-Supply Limits and Illicit Overdose Substitution

required_packages <- c(
  "tidyverse",    # data manipulation and plotting
  "fixest",       # fast fixed effects estimation
  "did",          # Callaway-Sant'Anna staggered DiD
  "httr",         # HTTP requests for CDC API
  "jsonlite",     # JSON parsing
  "modelsummary", # regression tables
  "kableExtra",   # table formatting
  "sandwich",     # robust standard errors
  "HonestDiD",    # Rambachan-Roth sensitivity
  "bacondecomp",  # Bacon decomposition
  "fwildclusterboot" # wild cluster bootstrap
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
