# 00_packages.R
# SNAP Emergency Allotment Expiration and Labor Supply
# Install and load all required packages

# Install packages if not already installed
packages_needed <- c(
  "tidyverse",
  "fixest",
  "did",
  "duckdb",
  "jsonlite",
  "fredr",
  "DBI",
  "lubridate",
  "modelsummary",
  "kableExtra",
  "scales",
  "ggplot2",
  "patchwork"
)

for (pkg in packages_needed) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
}

# Load all packages explicitly
library(tidyverse)
library(fixest)
library(did)
library(duckdb)
library(jsonlite)
library(fredr)
library(DBI)
library(lubridate)
library(modelsummary)
library(kableExtra)
library(scales)
library(ggplot2)
library(patchwork)

cat("All packages loaded successfully.\n")
cat("Package versions:\n")
cat("  tidyverse:", as.character(packageVersion("tidyverse")), "\n")
cat("  fixest:", as.character(packageVersion("fixest")), "\n")
cat("  did:", as.character(packageVersion("did")), "\n")
cat("  duckdb:", as.character(packageVersion("duckdb")), "\n")
cat("  fredr:", as.character(packageVersion("fredr")), "\n")
