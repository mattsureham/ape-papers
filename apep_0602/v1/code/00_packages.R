## 00_packages.R — Load libraries and set defaults
## apep_0602: CDR Threshold and For-Profit College Behavior

library(tidyverse)
library(fixest)
library(rdrobust)
library(rddensity)
library(httr)
library(jsonlite)
library(duckdb)
library(DBI)

# Set seed for reproducibility
set.seed(20260312)

# Working directory
setwd(file.path(dirname(dirname(rstudioapi::getActiveDocumentContext()$path %||% "."))))
if (!dir.exists("data")) dir.create("data", recursive = TRUE)
if (!dir.exists("tables")) dir.create("tables", recursive = TRUE)

cat("Packages loaded successfully.\n")
