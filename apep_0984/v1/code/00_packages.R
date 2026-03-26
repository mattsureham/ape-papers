## 00_packages.R — Install and load required packages
## Paper: The Deterrence Dividend (apep_0984)

pkgs <- c("tidyverse", "fixest", "did", "quantmod", "httr", "jsonlite",
          "gtrendsR", "zoo", "xtable")

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
}

library(tidyverse)
library(fixest)
library(did)
library(quantmod)
library(httr)
library(jsonlite)
library(gtrendsR)
library(zoo)
library(xtable)

cat("All packages loaded.\n")
