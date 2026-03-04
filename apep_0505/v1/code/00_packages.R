## ============================================================
## 00_packages.R — Load libraries and set defaults
## apep_0505: Council Tax Support Localization
## ============================================================

## CRAN packages
pkgs <- c(
  "tidyverse",      # Data manipulation and plotting
  "data.table",     # Fast large-data operations
  "fixest",         # Fixed-effects estimation (feols, fepois)
  "did",            # Callaway-Sant'Anna DiD
  "HonestDiD",      # Rambachan-Roth sensitivity bounds
  "modelsummary",   # Regression tables
  "kableExtra",     # LaTeX table formatting
  "ggthemes",       # Clean plot themes
  "readODS",        # Read ODS files from gov.uk
  "readxl",         # Read Excel files from gov.uk
  "httr",           # HTTP requests
  "jsonlite",       # JSON parsing
  "sf",             # Spatial data (LA boundaries)
  "scales",         # Axis formatting
  "patchwork",      # Plot composition
  "sandwich",       # Robust SE
  "lmtest",         # Coefficient tests
  "fwildclusterboot" # Wild cluster bootstrap
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  suppressPackageStartupMessages(library(p, character.only = TRUE))
}

## Load .env file (API keys)
env_file <- normalizePath(file.path(getwd(), "../../../..", ".env"),
                          mustWork = FALSE)
if (!file.exists(env_file)) {
  env_file <- normalizePath("../../../../.env", mustWork = FALSE)
}
if (file.exists(env_file)) {
  lines <- readLines(env_file, warn = FALSE)
  for (line in lines) {
    line <- trimws(line)
    if (nchar(line) == 0 || startsWith(line, "#")) next
    eq_pos <- regexpr("=", line, fixed = TRUE)
    if (eq_pos > 0) {
      key <- trimws(substr(line, 1, eq_pos - 1))
      val <- trimws(substr(line, eq_pos + 1, nchar(line)))
      val <- gsub("^[\"']|[\"']$", "", val)
      if (nchar(key) > 0) {
        args <- list(val)
        names(args) <- key
        do.call(Sys.setenv, args)
      }
    }
  }
  cat("Loaded .env file.\n")
} else {
  cat("WARNING: .env file not found at", env_file, "\n")
}

## Global settings
options(scipen = 999,
        modelsummary_factory_latex = "kableExtra")
theme_set(theme_minimal(base_size = 12) +
            theme(panel.grid.minor = element_blank(),
                  plot.title = element_text(face = "bold")))

## Paths
BASE_DIR <- file.path(getwd(), "..")
DATA_DIR <- file.path(BASE_DIR, "data")
FIG_DIR  <- file.path(BASE_DIR, "figures")
TAB_DIR  <- file.path(BASE_DIR, "tables")
dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(FIG_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(TAB_DIR, showWarnings = FALSE, recursive = TRUE)

cat("Packages loaded. Directories set.\n")
