## ===========================================================
## 00_packages.R — Load libraries, set defaults
## APEP-0500: Anti-Open Grazing Laws and Farmer-Herder Violence
## ===========================================================

# Core
library(tidyverse)
library(data.table)
library(sf)

# Econometrics
library(fixest)
library(did)          # Callaway-Sant'Anna
library(HonestDiD)    # Rambachan-Roth sensitivity
library(fwildclusterboot)  # Wild cluster bootstrap

# Visualization
library(ggplot2)
library(patchwork)
library(scales)
library(viridis)

# Tables
library(modelsummary)
library(kableExtra)

# ggplot defaults
theme_apep <- theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold", size = 12),
    plot.subtitle = element_text(size = 10, color = "gray40"),
    legend.position = "bottom",
    strip.text = element_text(face = "bold")
  )
theme_set(theme_apep)

# Project paths (relative to code/ directory)
data_dir <- file.path("..", "data")
fig_dir  <- file.path("..", "figures")
tab_dir  <- file.path("..", "tables")

dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(tab_dir, showWarnings = FALSE, recursive = TRUE)

cat("Packages loaded. Directories set.\n")
