## ============================================================
## 00_packages.R — Load libraries and set global options
## ERDF Treatment Withdrawal RDD
## ============================================================

# Core data manipulation
library(data.table)
library(dplyr)
library(tidyr)
library(stringr)

# Eurostat data access
library(eurostat)

# Econometric packages
library(fixest)
library(rdrobust)
library(rddensity)

# Visualization
library(ggplot2)
library(patchwork)
library(scales)
library(ggrepel)

# Tables
library(kableExtra)
library(modelsummary)

# HTTP for cohesion data API
library(httr)
library(jsonlite)

# Set global theme
theme_set(theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold", size = 12),
    plot.subtitle = element_text(size = 10, color = "grey40"),
    axis.title = element_text(size = 10),
    legend.position = "bottom"
  ))

# Reproducibility
set.seed(20260310)

cat("All packages loaded successfully.\n")
