# =============================================================================
# 00_packages.R — Right-to-Try Laws and the Market for Clinical Trials
# =============================================================================

# Core data manipulation
library(data.table)
library(jsonlite)
library(httr)

# Econometrics
library(fixest)       # TWFE, event studies
library(did)          # Callaway-Sant'Anna estimator
library(HonestDiD)    # Sensitivity analysis for DiD

# Visualization
library(ggplot2)
library(patchwork)
library(scales)

# Table output
library(modelsummary)

# Set global theme
theme_set(
  theme_minimal(base_size = 11) +
    theme(
      panel.grid.minor = element_blank(),
      strip.text = element_text(face = "bold"),
      plot.title = element_text(face = "bold", size = 12),
      legend.position = "bottom"
    )
)

# Paths
DATA_DIR   <- file.path("..", "data")
FIG_DIR    <- file.path("..", "figures")
TABLE_DIR  <- file.path("..", "tables")

dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(FIG_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(TABLE_DIR, showWarnings = FALSE, recursive = TRUE)

cat("Packages loaded. Data:", DATA_DIR, "| Figures:", FIG_DIR, "| Tables:", TABLE_DIR, "\n")
