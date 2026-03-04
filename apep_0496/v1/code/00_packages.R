## =============================================================================
## 00_packages.R — Load libraries and set global options
## apep_0496: Education Priority Labels and Housing Markets in France
## =============================================================================

# Core data manipulation
library(data.table)
library(dplyr)
library(tidyr)
library(stringr)

# Spatial analysis
library(sf)
library(units)

# Econometrics
library(rdrobust)      # RDD estimation (Calonico, Cattaneo, Titiunik)
library(rddensity)     # McCrary density tests
library(fixest)        # Fast fixed effects estimation
library(sandwich)
library(lmtest)

# Figures
library(ggplot2)
library(patchwork)
library(scales)

# Nearest neighbor
library(RANN)          # Fast kd-tree nearest neighbor search

# Data I/O
library(arrow)         # Parquet reading
library(jsonlite)

# Set global theme
theme_set(theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold", size = 12),
    plot.subtitle = element_text(color = "grey40"),
    strip.text = element_text(face = "bold")
  ))

# Suppress scientific notation
options(scipen = 999)

cat("Packages loaded successfully.\n")
