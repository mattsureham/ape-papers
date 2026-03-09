# ==============================================================================
# 00_packages.R — Load libraries and set themes
# The Credential Cliff: Multi-Cutoff RDD on South Africa Matric Pass Levels
# ==============================================================================

# Core data manipulation
library(tidyverse)
library(data.table)

# Econometrics
library(fixest)
library(rdrobust)
library(rddensity)
library(rdlocrand)
library(sandwich)
library(lmtest)

# Figures and tables
library(ggplot2)
library(scales)
library(patchwork)
library(kableExtra)

# Data access
library(httr)
library(jsonlite)
library(haven)       # Read Stata .dta files
library(readxl)

# Set APEP ggplot theme
theme_apep <- theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    axis.line = element_line(color = "black", linewidth = 0.3),
    axis.ticks = element_line(color = "black", linewidth = 0.3),
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 11, color = "gray30"),
    legend.position = "bottom",
    strip.text = element_text(face = "bold")
  )
theme_set(theme_apep)

# Color palette
apep_colors <- c(
  "Higher Certificate" = "#E41A1C",
  "Diploma" = "#377EB8",
  "Bachelor's" = "#4DAF4A",
  "Fail" = "#999999"
)

cat("Packages loaded successfully.\n")
