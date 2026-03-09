## =============================================================================
## 00_packages.R — Load Libraries and Set Global Options
## Paper: The Economic Integration Lottery
## =============================================================================

# Core
library(tidyverse)
library(data.table)
library(fixest)
library(sandwich)
library(lmtest)

# IV estimation
library(ivreg)

# Data access
library(httr)
library(jsonlite)

# Tables and figures
library(ggplot2)
library(scales)
library(kableExtra)
library(modelsummary)

# Spatial (for court-county mapping)
library(sf)

# Set global options
options(scipen = 999)
setFixest_nthreads(parallel::detectCores())

# APEP theme for figures
theme_apep <- function(base_size = 11) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title = element_text(face = "bold", size = base_size + 2),
      plot.subtitle = element_text(color = "grey40", size = base_size),
      axis.title = element_text(size = base_size),
      axis.text = element_text(size = base_size - 1),
      legend.position = "bottom",
      legend.title = element_text(size = base_size - 1),
      panel.grid.minor = element_blank(),
      plot.caption = element_text(hjust = 0, color = "grey50", size = base_size - 2),
      strip.text = element_text(face = "bold")
    )
}

theme_set(theme_apep())

cat("Packages loaded successfully.\n")
