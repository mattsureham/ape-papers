## =============================================================
## 00_packages.R — Load libraries and set global options
## apep_0544: Russian Gas Shock and European Manufacturing
## =============================================================

# Core
library(data.table)
library(fixest)
library(ggplot2)
library(scales)
library(viridis)

# Data access
library(httr)
library(jsonlite)

# Tables
library(modelsummary)
library(kableExtra)

# Utilities
library(stringr)

# ggplot theme
theme_set(theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    strip.text = element_text(face = "bold"),
    legend.position = "bottom",
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(color = "gray40"),
    plot.caption = element_text(color = "gray60", size = 8)
  ))

# Paths
DATA_DIR  <- file.path(getwd(), "..", "data")
FIG_DIR   <- file.path(getwd(), "..", "figures")
TABLE_DIR <- file.path(getwd(), "..", "tables")

dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(FIG_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(TABLE_DIR, showWarnings = FALSE, recursive = TRUE)

cat("Packages loaded. Data:", DATA_DIR, "\n")
