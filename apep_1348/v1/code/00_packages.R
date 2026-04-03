# 00_packages.R — Load required libraries
# apep_1348: Groningen Regulatory Rebound

if (!require("pacman")) install.packages("pacman")
pacman::p_load(
  tidyverse,
  fixest,
  httr,
  jsonlite,
  sf,
  geosphere,
  xtable,
  stargazer,
  data.table
)

cat("All packages loaded.\n")
