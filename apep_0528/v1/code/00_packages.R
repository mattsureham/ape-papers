## 00_packages.R — Load libraries and set global options
## APEP-0528: Do Administrative Borders Tax Electricity?

# Core data manipulation
library(data.table)
library(dplyr)
library(tidyr)
library(readr)
library(stringr)

# Spatial analysis
library(sf)
library(terra)

# Econometrics
library(fixest)      # High-dimensional FE / event studies
library(rdrobust)    # RDD estimation
library(rddensity)   # McCrary density test

# Graphics
library(ggplot2)
library(patchwork)
library(scales)

# HTTP/SPARQL
library(httr)
library(jsonlite)

# Set ggplot theme
theme_set(theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold", size = 12),
    strip.text = element_text(face = "bold"),
    legend.position = "bottom"
  ))

# Global options
options(scipen = 999)

cat("Packages loaded successfully.\n")
