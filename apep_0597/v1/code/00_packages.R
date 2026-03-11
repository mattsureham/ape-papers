## =============================================================================
## 00_packages.R — Load required libraries and set global options
## Paper: Pump Price Pass-Through After Nigeria's 2023 Fuel Subsidy Removal
## =============================================================================

# Core packages
library(tidyverse)
library(data.table)
library(fixest)

# Spatial/geographic
library(sf)
library(geodist)

# Visualization
library(ggplot2)
library(patchwork)
library(scales)
library(knitr)
library(kableExtra)

# Robust inference
library(sandwich)

# Wild cluster bootstrap
if (!requireNamespace("fwildclusterboot", quietly = TRUE))
  install.packages("fwildclusterboot", repos = "https://cloud.r-project.org")
library(fwildclusterboot)

# Set ggplot theme
theme_set(
  theme_minimal(base_size = 12) +
    theme(
      panel.grid.minor = element_blank(),
      plot.title = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(size = 11, color = "gray40"),
      legend.position = "bottom",
      strip.text = element_text(face = "bold")
    )
)

# Suppress scientific notation
options(scipen = 999)

cat("All packages loaded successfully.\n")
