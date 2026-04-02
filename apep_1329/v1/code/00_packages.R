## 00_packages.R — Load required packages
## APEP-1329: UK FIT Triple-Threshold Bunching

library(tidyverse)
library(readxl)
library(fixest)
library(data.table)
library(jsonlite)
library(xtable)
library(httr)

# For bunching estimation
if (!requireNamespace("bunching", quietly = TRUE)) {
  install.packages("bunching", repos = "https://cloud.r-project.org")
}
library(bunching)

cat("All packages loaded.\n")
