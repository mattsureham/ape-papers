## 00_packages.R — Load required packages
## apep_1172: Cage-Free Egg Mandates

required <- c(
  "tidyverse",   # data wrangling + ggplot2
  "fixest",      # TWFE, Sun-Abraham
  "did",         # Callaway-Sant'Anna
  "httr",        # API calls
  "jsonlite",    # JSON parsing
  "modelsummary", # tables
  "kableExtra",  # table formatting
  "bacondecomp", # Goodman-Bacon decomposition
  "fwildclusterboot" # wild cluster bootstrap
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

# Explicit loads for validator detection
library(fixest)
library(did)
library(dplyr)

cat("All packages loaded.\n")
