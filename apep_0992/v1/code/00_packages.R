# 00_packages.R — Load required libraries
# APEP Working Paper apep_0992

library(tidyverse)
library(fixest)
library(data.table)
library(jsonlite)
library(xtable)

# Set working directory to paper root
if (basename(getwd()) == "code") setwd("..")
cat("Working directory:", getwd(), "\n")
