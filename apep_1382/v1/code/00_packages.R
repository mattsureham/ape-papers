#!/usr/bin/env Rscript
# Load required packages

library(tidyverse)
library(data.table)
library(fixest)
library(httr2)
library(jsonlite)
library(readr)

# Suppress warnings for cleaner output
options(warn = -1)
options(dplyr.summarise.inform = FALSE)

cat("Packages loaded successfully\n")
