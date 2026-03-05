## ============================================================
## 00_packages.R — Load libraries and set global options
## apep_0516: PTZ Geographic Withdrawal and Housing Markets
## ============================================================

# Core data manipulation
library(data.table)
library(arrow)

# Econometrics
library(fixest)
library(did)          # Callaway-Sant'Anna
library(HonestDiD)    # Rambachan-Roth sensitivity

# Visualization
library(ggplot2)
library(patchwork)
library(scales)

# Tables
library(modelsummary)

# Misc
library(readxl)

# Set global options
setFixest_nthreads(4)
options(scipen = 999)

# Theme for figures
theme_apep <- theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    plot.title = element_text(face = "bold", size = 12),
    plot.subtitle = element_text(size = 10, color = "grey40"),
    legend.position = "bottom",
    strip.text = element_text(face = "bold")
  )
theme_set(theme_apep)

# Palette
zone_colors <- c("B1" = "#2166AC", "B2" = "#D6604D", "C" = "#B2182B")

cat("Packages loaded successfully.\n")
