## 00_packages.R — Load required libraries
## apep_0960: Zambia mining royalty reform and nightlights

library(tidyverse)
library(fixest)
library(sf)
library(jsonlite)
library(WDI)
library(fwildclusterboot)
library(sandwich)
library(lmtest)
library(blackmarbler)
library(geodata)

# Suppress scientific notation
options(scipen = 999)

cat("All packages loaded successfully.\n")
