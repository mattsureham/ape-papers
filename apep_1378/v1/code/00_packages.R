# Load packages
library(tidyverse)
library(data.table)
library(httr2)
library(jsonlite)
library(fixest)      # Modern econometrics (ivfplot, etable)
library(ivreg)       # 2SLS with diagnostics
library(stargazer)   # Table export
library(readxl)

# Set working directory (go up to v1 folder)
setwd("..")

# Seed for reproducibility
set.seed(20260407)

print("Packages loaded")
