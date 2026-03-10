# ==============================================================================
# 00_packages.R — Package Setup for apep_0588
# Frozen Out: Russian Gas Shock and Excess Winter Mortality
# ==============================================================================

# Core packages
library(data.table)
library(fixest)
library(ggplot2)
library(eurostat)

# Data manipulation
library(lubridate)
library(stringr)
library(httr)
library(jsonlite)

# Inference
library(fwildclusterboot)  # Wild cluster bootstrap for small N clusters
library(sandwich)
library(lmtest)

# Tables
library(xtable)
library(knitr)

# Set ggplot theme
theme_set(
  theme_minimal(base_size = 12) +
    theme(
      panel.grid.minor = element_blank(),
      plot.title = element_text(face = "bold", size = 14),
      axis.title = element_text(size = 11),
      legend.position = "bottom"
    )
)

# Color palette for gas dependence groups
gas_cols <- c(
  "High (>50%)" = "#d73027",
  "Medium (25-50%)" = "#fc8d59",
  "Low (<25%)" = "#4575b4"
)

cat("Packages loaded successfully.\n")
