# 00_packages.R — Required packages for bunching analysis
# apep_0716: Nonprofit Disclosure Cost Bunching

required_packages <- c(
  "tidyverse",    # Data manipulation and plotting
  "data.table",   # Fast CSV reading
  "fixest",       # Fixed effects (heterogeneity analysis)
  "jsonlite",     # Diagnostics output
  "xtable",       # LaTeX table generation
  "boot",         # Bootstrap inference
  "scales"        # Number formatting
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
