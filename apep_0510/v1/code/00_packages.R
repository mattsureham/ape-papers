# =============================================================================
# 00_packages.R — Pills and Diplomas (apep_0510)
# =============================================================================
# Load all required packages and set global options.

# --- Package installation check ---
required_pkgs <- c(
  "duckdb", "DBI", "data.table", "fixest", "did", "HonestDiD",
  "ggplot2", "scales", "patchwork", "httr", "jsonlite",
  "kableExtra", "modelsummary", "broom", "bacondecomp",
  "maps", "tidyverse"
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
}

# --- Load ---
library(duckdb)
library(DBI)
library(data.table)
library(fixest)
library(did)
library(HonestDiD)
library(ggplot2)
library(scales)
library(patchwork)
library(httr)
library(jsonlite)
library(kableExtra)
library(modelsummary)
library(broom)
library(bacondecomp)

# --- Global options ---
setFixest_nthreads(parallel::detectCores())
options(scipen = 999)

# --- APEP ggplot theme ---
theme_apep <- theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    axis.line = element_line(color = "grey30", linewidth = 0.3),
    axis.ticks = element_line(color = "grey30", linewidth = 0.3),
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(color = "grey40", size = 10),
    plot.caption = element_text(color = "grey50", size = 8, hjust = 0),
    legend.position = "bottom",
    strip.text = element_text(face = "bold")
  )
theme_set(theme_apep)

# --- Paths ---
DATA_DIR  <- "data"
FIG_DIR   <- "figures"
TABLE_DIR <- "tables"
dir.create(DATA_DIR, showWarnings = FALSE)
dir.create(FIG_DIR, showWarnings = FALSE)
dir.create(TABLE_DIR, showWarnings = FALSE)

cat("Packages loaded. Ready for analysis.\n")
