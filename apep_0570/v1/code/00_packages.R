# ==============================================================================
# 00_packages.R — Load all required libraries
# APEP-0570: Malaysia GST-to-SST Tax Pass-Through
# ==============================================================================

# Core data manipulation
library(data.table)
library(arrow)         # Read Parquet files

# Econometrics
library(fixest)        # TWFE, event studies
library(sandwich)      # Robust SEs
library(lmtest)        # Coeftest

# Visualization
library(ggplot2)
library(patchwork)     # Combine plots
library(scales)        # Formatting

# Tables
library(modelsummary)  # Regression tables
library(kableExtra)    # Table formatting

# Set ggplot2 theme
theme_set(
  theme_minimal(base_size = 12) +
    theme(
      panel.grid.minor = element_blank(),
      plot.title = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(color = "grey40"),
      legend.position = "bottom",
      strip.text = element_text(face = "bold")
    )
)

cat("All packages loaded successfully.\n")
