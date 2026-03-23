# 00_packages.R — Load required packages
# apep_0827: Dutch cannabis supply chain experiment and crime

required_packages <- c(
  "tidyverse",    # Data manipulation and plotting
  "fixest",       # Fixed effects estimation
  "jsonlite",     # JSON I/O
  "httr",         # HTTP requests for CBS API
  "Synth",        # Synthetic control method
  "boot",         # Bootstrap inference
  "knitr",        # Table formatting
  "xtable"        # LaTeX table output
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
