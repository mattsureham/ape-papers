## ============================================================
## 00_packages.R — Load libraries and set themes
## Cap On, Cap Off: Kenya's Interest Rate Ceiling (2016-2019)
## ============================================================

# Core data manipulation
library(tidyverse)
library(data.table)
library(janitor)

# Econometrics
library(fixest)      # Two-way FE, event studies
library(sandwich)    # Robust SEs
library(lmtest)      # Coefficient tests
library(broom)       # Tidy model output

# Inference
library(fwildclusterboot)  # Wild cluster bootstrap

# Tables and output
library(modelsummary)
library(kableExtra)
library(xtable)

# Figures
library(ggplot2)
library(patchwork)
library(scales)

# Data fetching
library(httr)
library(jsonlite)
# library(pdftools)  # Not needed — tier data constructed from published CBK tables

# Set ggplot theme
theme_apep <- theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(color = "grey40"),
    legend.position = "bottom",
    axis.title = element_text(size = 11),
    strip.text = element_text(face = "bold")
  )
theme_set(theme_apep)

# Color palette
apep_colors <- c(
  "cap_on"   = "#E41A1C",
  "cap_off"  = "#377EB8",
  "pre_cap"  = "#4DAF4A",
  "tier1"    = "#984EA3",
  "tier2"    = "#FF7F00",
  "tier3"    = "#A65628",
  "kenya"    = "#E41A1C",
  "uganda"   = "#377EB8",
  "tanzania" = "#4DAF4A",
  "rwanda"   = "#984EA3"
)

# Key dates
CAP_START  <- as.Date("2016-09-14")
CAP_REPEAL <- as.Date("2019-11-07")
COVID_START <- as.Date("2020-03-15")

# Directories
DATA_DIR <- file.path(dirname(getwd()), "data")
FIG_DIR  <- file.path(dirname(getwd()), "figures")
TAB_DIR  <- file.path(dirname(getwd()), "tables")

dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(FIG_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(TAB_DIR, showWarnings = FALSE, recursive = TRUE)

cat("Packages loaded. Theme set.\n")
cat("Cap start:", format(CAP_START), "\n")
cat("Cap repeal:", format(CAP_REPEAL), "\n")
cat("COVID start:", format(COVID_START), "\n")
