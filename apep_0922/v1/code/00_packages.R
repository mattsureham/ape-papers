## 00_packages.R — Install and load required packages
## APEP paper apep_0922: Alkaline Hydrolysis and Funeral Industry Competition

required_packages <- c(
  "data.table",    # Fast data manipulation
  "fixest",        # Fixed effects estimation
  "did",           # Callaway-Sant'Anna DiD
  "ggplot2",       # Plotting (for diagnostics only, not paper figures)
  "httr",          # HTTP requests for BLS API
  "jsonlite",      # JSON handling
  "sandwich",      # Robust standard errors
  "lmtest",        # Coefficient testing
  "modelsummary",  # Table generation
  "kableExtra"     # LaTeX table formatting
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

message("All packages loaded successfully.")
