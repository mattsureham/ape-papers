# 00_packages.R — Package setup for apep_0699
# Saudi Arabia guardianship reform and female LFP

required_packages <- c(
  "tidyverse",
  "fixest",
  "broom",
  "jsonlite",
  "ggplot2",
  "knitr",
  "kableExtra",
  "scales",
  "wbstats",
  "httr",
  "readxl",
  "lubridate",
  "glue",
  "modelsummary",
  "sandwich",
  "lmtest",
  "boot",
  "did"
)

installed <- installed.packages()[, "Package"]
to_install <- setdiff(required_packages, installed)
if (length(to_install) > 0) {
  cat("Installing packages:", paste(to_install, collapse=", "), "\n")
  install.packages(to_install, repos = "https://cran.rstudio.com/")
}

suppressPackageStartupMessages({
  library(tidyverse)
  library(fixest)
  library(broom)
  library(jsonlite)
  library(ggplot2)
  library(knitr)
  library(kableExtra)
  library(scales)
  library(wbstats)
  library(httr)
  library(lubridate)
  library(glue)
  library(modelsummary)
})

cat("All packages loaded successfully.\n")
