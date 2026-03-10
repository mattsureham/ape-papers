## ============================================================
## 00_packages.R — Load libraries, set themes
## apep_0573: EU Procurement Reform and Competition
## ============================================================

# --- Package installation (idempotent) ---
required_pkgs <- c(
  "data.table", "fixest", "ggplot2", "did", "dplyr", "tidyr",
  "readr", "stringr", "lubridate", "httr", "jsonlite", "curl",
  "xtable", "kableExtra", "scales", "purrr",
  "HonestDiD", "eurostat", "countrycode"
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
}

# --- Load ---
suppressPackageStartupMessages({
  library(data.table)
  library(fixest)
  library(ggplot2)
  library(did)
  library(dplyr)
  library(tidyr)
  library(readr)
  library(stringr)
  library(lubridate)
  library(httr)
  library(jsonlite)
  library(curl)
  library(xtable)
  library(scales)
  library(purrr)
  library(countrycode)
})

# --- ggplot theme ---
theme_apep <- theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 11, color = "grey40"),
    legend.position = "bottom",
    strip.text = element_text(face = "bold")
  )
theme_set(theme_apep)

# --- Paths ---
# Derive base_dir from this script's location for portability
.this_script <- tryCatch(normalizePath(sys.frame(1)$ofile), error = function(e) NULL)
if (!is.null(.this_script)) {
  base_dir <- dirname(dirname(.this_script))
} else {
  base_dir <- Sys.getenv("APEP_BASE_DIR", unset = file.path("output", "apep_0573", "v1"))
}
data_dir <- file.path(base_dir, "data")
fig_dir  <- file.path(base_dir, "figures")
tab_dir  <- file.path(base_dir, "tables")
code_dir <- file.path(base_dir, "code")

dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir,  showWarnings = FALSE, recursive = TRUE)
dir.create(tab_dir,  showWarnings = FALSE, recursive = TRUE)

cat("Packages loaded. Base dir:", base_dir, "\n")
