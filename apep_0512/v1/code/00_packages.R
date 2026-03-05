# ==============================================================================
# 00_packages.R — Load libraries and set options
# Paper: Who Bears the Tax Cut? (apep_0512)
# ==============================================================================

# Core
library(tidyverse)
library(data.table)

# Econometrics
library(fixest)

# Tables and output
library(modelsummary)

# Figures
library(ggplot2)
library(scales)

# Excel reading
library(readxl)

# Set APEP theme
theme_apep <- theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold", size = 12),
    plot.subtitle = element_text(size = 10, color = "grey40"),
    strip.text = element_text(face = "bold"),
    legend.position = "bottom"
  )
theme_set(theme_apep)

# Paths — scripts run from code/ directory
code_dir <- getwd()
base_dir <- dirname(code_dir)
data_dir <- file.path(code_dir, "data")
fig_dir  <- file.path(base_dir, "figures")
tab_dir  <- file.path(base_dir, "tables")

dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir,  showWarnings = FALSE, recursive = TRUE)
dir.create(tab_dir,  showWarnings = FALSE, recursive = TRUE)

cat("Packages loaded. Base dir:", base_dir, "\n")
cat("Data dir:", data_dir, "\n")
