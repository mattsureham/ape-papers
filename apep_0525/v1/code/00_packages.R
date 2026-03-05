# ============================================================================
# 00_packages.R — Load libraries and set global options
# APEP-0525: Tax Borders and the Rich
# ============================================================================

# --- Core packages ---
library(data.table)
library(fixest)
library(ggplot2)
library(sf)
library(rdrobust)
library(rddensity)

# --- Supporting packages ---
library(scales)
library(stringr)
library(xtable)

# --- Global settings ---
setDTthreads(4)
options(scipen = 999)

# --- ggplot theme ---
theme_set(
  theme_minimal(base_size = 12) +
    theme(
      panel.grid.minor = element_blank(),
      plot.title = element_text(face = "bold", size = 14),
      axis.title = element_text(size = 11),
      legend.position = "bottom"
    )
)

# --- Paths ---
BASE_DIR <- file.path(getwd(), "..")
DATA_DIR <- file.path(BASE_DIR, "data")
FIG_DIR  <- file.path(BASE_DIR, "figures")
TAB_DIR  <- file.path(BASE_DIR, "tables")

dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(FIG_DIR,  showWarnings = FALSE, recursive = TRUE)
dir.create(TAB_DIR,  showWarnings = FALSE, recursive = TRUE)

cat("Packages loaded. Base directory:", BASE_DIR, "\n")
