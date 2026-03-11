# ==============================================================================
# 00_packages.R — Load packages and set global options
# Paper: Trade Protection by Fiat (apep_0595)
# ==============================================================================

# --- Core ---
library(tidyverse)
library(data.table)
library(fixest)

# --- DiD / Causal Inference ---
library(did)         # Callaway-Sant'Anna
library(HonestDiD)   # Rambachan-Roth sensitivity

# --- Inference ---
if (requireNamespace("fwildclusterboot", quietly = TRUE)) {
  library(fwildclusterboot)
}
library(sandwich)
library(lmtest)

# --- Spatial ---
library(sf)
library(geosphere)   # Distance calculations

# --- Tables / Output ---
library(knitr)
library(kableExtra)
library(modelsummary)

# --- Figures ---
library(ggplot2)
library(patchwork)
library(scales)

# --- APEP ggplot theme ---
theme_apep <- function(base_size = 11) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title = element_text(face = "bold", size = base_size + 2),
      plot.subtitle = element_text(color = "grey40"),
      panel.grid.minor = element_blank(),
      panel.grid.major.x = element_blank(),
      strip.text = element_text(face = "bold"),
      legend.position = "bottom",
      plot.caption = element_text(hjust = 0, color = "grey50", size = base_size - 2)
    )
}
theme_set(theme_apep())

# --- Paths (auto-detected from code/ working directory) ---
BASE_DIR <- normalizePath("..", mustWork = TRUE)
DATA_DIR <- file.path(BASE_DIR, "data")
FIG_DIR  <- file.path(BASE_DIR, "figures")
TAB_DIR  <- file.path(BASE_DIR, "tables")
CODE_DIR <- file.path(BASE_DIR, "code")

dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(FIG_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(TAB_DIR, showWarnings = FALSE, recursive = TRUE)

cat("Packages loaded. Base directory:", BASE_DIR, "\n")
