## 00_packages.R — Load and install required packages
pkgs <- c("tidyverse", "fixest", "httr", "jsonlite", "tidycensus", "broom", "kableExtra")
for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cran.r-project.org")
}
library(tidyverse)
library(fixest)
library(httr)
library(jsonlite)
library(tidycensus)
library(broom)
library(kableExtra)
cat("All packages loaded.\n")
