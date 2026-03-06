# 00_packages.R — Load libraries and set defaults
# APEP-0540: Grand Paris Express Construction-Phase Capitalization

required_packages <- c(
  "data.table", "arrow", "duckdb",       # data handling
  "sf", "units",                           # spatial
  "fixest", "did", "HonestDiD",           # econometrics
  "modelsummary", "kableExtra",            # tables
  "ggplot2", "ggthemes", "patchwork",      # figures
  "scales", "viridis",                     # aesthetics
  "httr2", "jsonlite", "curl",            # API access
  "stringr", "lubridate"                   # utilities
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  suppressPackageStartupMessages(library(pkg, character.only = TRUE))
}

# ggplot defaults
theme_set(theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "bottom",
    plot.title = element_text(face = "bold", size = 12),
    strip.text = element_text(face = "bold")
  ))

# Paths
BASE_DIR <- file.path(getwd())
DATA_DIR <- file.path(BASE_DIR, "data")
FIG_DIR  <- file.path(BASE_DIR, "figures")
TAB_DIR  <- file.path(BASE_DIR, "tables")

dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(FIG_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(TAB_DIR, showWarnings = FALSE, recursive = TRUE)

# IDF department codes
IDF_DEPS <- c("75", "77", "78", "91", "92", "93", "94", "95")

cat("Packages loaded. Working directory:", getwd(), "\n")
