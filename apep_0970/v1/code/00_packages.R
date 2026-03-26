# 00_packages.R — Install and load required packages
# apep_0970: UI Duration Cuts and Education Gradient

required_packages <- c(
 "tidyverse",    # data manipulation + ggplot2
 "fixest",       # TWFE and Sun-Abraham
 "did",          # Callaway-Sant'Anna
 "arrow",        # read parquet from Azure
 "DBI",          # database interface
 "duckdb",       # in-memory SQL engine for parquet
 "jsonlite",     # write diagnostics.json
 "modelsummary", # regression tables
 "kableExtra",   # table formatting
 "sandwich",     # robust standard errors
 "HonestDiD"     # Rambachan-Roth sensitivity
)

for (pkg in required_packages) {
 if (!requireNamespace(pkg, quietly = TRUE)) {
   install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
 }
 library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
