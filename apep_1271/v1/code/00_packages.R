# 00_packages.R — Load and install required packages
# Paper: Mandated to Stay (apep_1271)

required_pkgs <- c(
  "arrow",        # Parquet / Azure reads
  "duckdb",       # SQL on Parquet
  "DBI",          # Database interface
  "data.table",   # Fast data manipulation
  "fixest",       # TWFE / Sun-Abraham
  "did",          # Callaway-Sant'Anna
  "ggplot2",      # Plotting (event studies)
  "modelsummary", # Table generation
  "kableExtra",   # LaTeX table formatting
  "jsonlite",     # diagnostics.json
  "sandwich",     # Robust SEs
  "fwildclusterboot", # Wild cluster bootstrap
  "HonestDiD"     # Sensitivity analysis
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
}

# Explicit library calls for validator detection
library(data.table)
library(fixest)
library(did)
library(arrow)
library(duckdb)
library(DBI)
library(ggplot2)
library(modelsummary)
library(kableExtra)
library(jsonlite)
library(sandwich)
library(fwildclusterboot)
library(HonestDiD)

cat("All packages loaded successfully.\n")
