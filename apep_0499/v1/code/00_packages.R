## 00_packages.R — Load libraries and set global options
## apep_0499: Action Cœur de Ville and Property Markets

# Core packages
library(tidyverse)
library(data.table)
library(fixest)
library(did)
library(ggplot2)

# Spatial
library(sf)

# Tables
library(modelsummary)
library(kableExtra)

# Additional
library(broom)
library(arrow)   # for parquet if needed
library(httr2)   # for API calls
library(jsonlite) # for JSON parsing

# Set ggplot theme
theme_apep <- theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold", size = 12),
    plot.subtitle = element_text(size = 10, color = "gray40"),
    strip.text = element_text(face = "bold"),
    legend.position = "bottom"
  )
theme_set(theme_apep)

# Global options
options(scipen = 999)
setFixest_nthreads(4)

cat("Packages loaded successfully.\n")
