## 00_packages.R — Load libraries and set themes
## APEP-0585: EU Medical Device Regulation (MDR) and Innovation

# Core data manipulation
library(tidyverse)
library(data.table)
library(jsonlite)
library(httr)

# Econometrics
library(fixest)
library(sandwich)
library(lmtest)

# Plotting
library(ggplot2)
library(patchwork)
library(scales)
library(latex2exp)

# Tables
library(kableExtra)
library(modelsummary)

# ── APEP Standard Theme ──
theme_apep <- function() {
  theme_minimal(base_size = 12) +
    theme(
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(color = "grey90", linewidth = 0.3),
      axis.line = element_line(color = "grey30", linewidth = 0.4),
      axis.ticks = element_line(color = "grey30", linewidth = 0.3),
      axis.title = element_text(size = 11, face = "bold"),
      axis.text = element_text(size = 10, color = "grey30"),
      legend.position = "bottom",
      legend.title = element_text(size = 10, face = "bold"),
      legend.text = element_text(size = 9),
      plot.title = element_text(size = 13, face = "bold", hjust = 0),
      plot.subtitle = element_text(size = 10, color = "grey40", hjust = 0),
      plot.caption = element_text(size = 8, color = "grey50", hjust = 1),
      plot.margin = margin(10, 15, 10, 10)
    )
}

apep_colors <- c(
  "#0072B2",  # Blue (treated / medical devices)
  "#D55E00",  # Orange (control / pharma)
  "#009E73",  # Green (instruments)
  "#CC79A7",  # Pink (electronics)
  "#F0E442",  # Yellow
  "#56B4E9"   # Light blue
)

cat("Packages loaded successfully.\n")
