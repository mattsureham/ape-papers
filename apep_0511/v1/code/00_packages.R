## ============================================================================
## 00_packages.R — Load libraries and set global options
## 340B Drug Pricing × Medicaid Drug Administration (RDD)
## ============================================================================

# Core data manipulation
library(data.table)
library(arrow)
library(dplyr)

# Econometrics
library(rdrobust)      # RDD estimation and inference
library(rddensity)     # McCrary-style density manipulation test
library(fixest)        # High-dimensional fixed effects (robustness)
library(sandwich)       # Robust standard errors
library(lmtest)         # Coefficient tests

# Visualization
library(ggplot2)
library(ggthemes)
library(patchwork)
library(scales)
library(kableExtra)

# Utilities
library(readr)
library(jsonlite)
library(httr)
library(stringr)

# Set global options
options(scipen = 999)
options(datatable.print.class = TRUE)

# Consistent theme for all figures
theme_set(
  theme_minimal(base_size = 11) +
    theme(
      plot.title = element_text(face = "bold", size = 13),
      plot.subtitle = element_text(color = "gray40", size = 10),
      panel.grid.minor = element_blank(),
      legend.position = "bottom",
      strip.text = element_text(face = "bold")
    )
)

# Color palette
pal_340b <- c(
  "Medicaid" = "#2166AC",
  "Medicare" = "#B2182B",
  "340B Eligible" = "#4DAF4A",
  "Not Eligible" = "#984EA3",
  "Placebo" = "#FF7F00"
)

cat("Packages loaded successfully.\n")
