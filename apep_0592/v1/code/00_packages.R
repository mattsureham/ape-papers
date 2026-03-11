# ==============================================================================
# 00_packages.R — Load libraries and set themes
# Paper: State Prohibition and Labor Market Restructuring (apep_0592)
# ==============================================================================

# Core data manipulation
library(data.table)
library(duckdb)
library(DBI)

# Econometrics
library(fixest)

# Visualization
library(ggplot2)
library(ggthemes)
library(scales)
library(patchwork)

# Tables
library(knitr)
library(kableExtra)

# Set ggplot theme
theme_set(theme_tufte(base_size = 11, base_family = "serif") +
            theme(plot.title = element_text(size = 12, face = "bold"),
                  plot.subtitle = element_text(size = 10),
                  strip.text = element_text(size = 10),
                  legend.position = "bottom"))

# Reproducibility
set.seed(20260311)

cat("All packages loaded successfully.\n")
