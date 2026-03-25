## 00_packages.R — Install and load required packages
## apep_0899: Finland compulsory education extension

pkgs <- c(
  "tidyverse",    # data manipulation + ggplot2

  "fixest",       # fast fixed effects (feols, sunab)
  "httr",         # HTTP requests for PxWeb API
  "jsonlite",     # JSON parsing
  "boot",             # bootstrap inference
  "did",          # Callaway-Sant'Anna
  "HonestDiD",    # Rambachan-Roth sensitivity
  "modelsummary", # table formatting
  "kableExtra",   # table output
  "sandwich",     # robust SEs
  "lmtest"        # coefficient tests
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
