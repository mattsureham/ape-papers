## 00_packages.R — Install and load required packages
## apep_0939: Employment Costs of Seismicity Regulation

pkgs <- c(
  "tidyverse",    # data manipulation and plotting
  "fixest",       # fast fixed effects estimation
  "did",          # Callaway-Sant'Anna DiD
  "httr",         # API calls
  "jsonlite",     # JSON parsing
  "readxl",       # OCC Excel files
  "data.table",   # fast data operations
  "fwildclusterboot", # wild cluster bootstrap
  "modelsummary", # table output
  "kableExtra",   # table formatting
  "HonestDiD"     # sensitivity analysis for parallel trends
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
