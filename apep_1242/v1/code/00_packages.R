# 00_packages.R — Required packages for PSC bunching analysis
# Install any missing packages
pkgs <- c("jsonlite", "data.table", "fixest", "ggplot2", "kableExtra",
          "boot", "MASS", "scales", "xtable")
for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
}

library(jsonlite)
library(data.table)
library(fixest)
library(boot)
library(MASS)
library(scales)
library(xtable)
cat("All packages loaded.\n")
