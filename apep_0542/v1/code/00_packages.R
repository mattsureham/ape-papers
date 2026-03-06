# ==============================================================================
# 00_packages.R — Load libraries and set themes
# Paper: When the Train Doesn't Come (apep_0542)
# ==============================================================================

# Core
library(data.table)
library(fixest)
library(ggplot2)
library(dplyr)
library(tidyr)
library(readr)
library(stringr)
library(sf)
library(httr2)
library(jsonlite)

# Spatial
library(geosphere)  # distHaversine

# Inference
library(sandwich)          # Robust SEs
# fwildclusterboot not available for this R version — use fixest::boottest instead

# ggplot theme
theme_set(
  theme_minimal(base_size = 12) +
    theme(
      panel.grid.minor = element_blank(),
      strip.text = element_text(face = "bold"),
      legend.position = "bottom",
      plot.title = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(color = "grey40")
    )
)

# Paths
DATA_DIR  <- file.path(getwd(), "data")
FIG_DIR   <- file.path(getwd(), "figures")
TABLE_DIR <- file.path(getwd(), "tables")

dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(FIG_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(TABLE_DIR, showWarnings = FALSE, recursive = TRUE)

cat("Packages loaded. Working directory:", getwd(), "\n")
