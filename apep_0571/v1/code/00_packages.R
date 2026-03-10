## =============================================================================
## 00_packages.R — Load libraries and set global options
## apep_0571: Voting reform and public safety in Chile
## =============================================================================

# Core
library(tidyverse)
library(data.table)

# Econometrics
library(fixest)      # TWFE, event study
library(sandwich)    # Robust SEs
library(lmtest)      # Coefficient tests

# Data I/O
library(readxl)
library(arrow)       # Parquet
library(haven)       # Stata files
library(jsonlite)

# Figures
library(ggplot2)
library(patchwork)
library(scales)

# Install if needed (suppress messages)
for (pkg in c("fwildbootstrap")) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
}

# ggplot theme
theme_apep <- theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold", size = 13),
    plot.subtitle = element_text(size = 10, color = "grey40"),
    axis.title = element_text(size = 11),
    legend.position = "bottom"
  )
theme_set(theme_apep)

cat("Packages loaded successfully.\n")
