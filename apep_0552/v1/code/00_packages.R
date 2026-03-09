# =============================================================================
# 00_packages.R — Load libraries and set global options
# APEP Paper apep_0552: Stranded by the Label?
# =============================================================================

# --- CRAN packages ---
required_pkgs <- c(
  "data.table", "arrow", "duckdb",     # data handling (out-of-core)
  "fixest",                              # fast fixed-effects estimation
  "rdrobust", "rddensity",              # RDD estimation and density tests
  "did",                                  # Callaway-Sant'Anna DiD
  "ggplot2", "ggthemes", "patchwork",    # figures
  "scales", "viridis",                   # figure formatting
  "modelsummary", "kableExtra",          # tables
  "sf",                                   # spatial operations
  "stringdist",                           # fuzzy string matching
  "httr", "jsonlite",                    # API calls
  "readxl",                              # Excel files
  "haven",                                # Stata files if needed
  "sandwich", "lmtest",                  # robust SEs
  "lubridate"                             # date handling
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

# --- Global settings ---
setDTthreads(parallel::detectCores() - 1)
options(scipen = 999)

# --- ggplot theme ---
theme_apep <- theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    legend.position = "bottom",
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 11, color = "gray30"),
    axis.title = element_text(size = 11),
    strip.text = element_text(face = "bold")
  )
theme_set(theme_apep)

# --- Paths ---
data_dir   <- file.path(getwd(), "..", "data")
fig_dir    <- file.path(getwd(), "..", "figures")
table_dir  <- file.path(getwd(), "..", "tables")

dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(table_dir, showWarnings = FALSE, recursive = TRUE)

cat("Packages loaded. Data dir:", data_dir, "\n")
