# ==============================================================================
# APEP-0509: MGNREGA, Input Substitution, and Crop-Specific Productivity
# 00_packages.R — Load libraries and set global options
# ==============================================================================

# --- Core data manipulation ---
library(data.table)
library(jsonlite)

# --- Econometrics ---
library(fixest)       # Fast fixed effects / CS-DiD via sunab()
library(did)          # Callaway & Sant'Anna (2021)

# --- Visualization ---
library(ggplot2)
library(patchwork)

# --- Tables ---
library(knitr)
library(kableExtra)

# --- Robustness ---
# HonestDiD for sensitivity analysis
if (!requireNamespace("HonestDiD", quietly = TRUE)) {
  install.packages("HonestDiD", repos = "https://cloud.r-project.org")
}
library(HonestDiD)

# --- Global settings ---
theme_set(theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold", size = 13),
    strip.text = element_text(face = "bold")
  ))

options(
  scipen = 999,
  digits = 4,
  fixest.dict = c(
    "log_yield" = "Log Yield (kg/ha)",
    "log_wage_male" = "Log Male Wage",
    "log_fert_total" = "Log Fertilizer/ha",
    "irr_share" = "Irrigated Share"
  )
)

# Set seed for reproducibility
set.seed(20250304)

cat("Packages loaded successfully.\n")
