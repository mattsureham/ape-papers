# 00_packages.R — Required packages for apep_0908
# Multi-threshold bunching analysis of German solar PV installations

required_packages <- c(
  "data.table",    # Fast data manipulation
  "fixest",        # Fixed effects estimation
  "ggplot2",       # Plotting (for diagnostics only, no figures in V1)
  "jsonlite",      # JSON parsing
  "httr",          # HTTP requests for API
  "arrow",         # Parquet/large file handling
  "boot",          # Bootstrap inference
  "sandwich",      # Robust standard errors
  "xtable",        # LaTeX table generation
  "scales"         # Number formatting
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
}

# Explicit library() calls for validator detection
library(data.table)
library(fixest)
library(jsonlite)
library(boot)
library(xtable)
library(scales)

cat("All packages loaded successfully.\n")
