# =============================================================================
# 00_packages.R — Load libraries and set defaults
# apep_1243: Municipal Consolidation and Residential Sorting in Switzerland
# =============================================================================

required_pkgs <- c(
  "data.table",
  "fixest",
  "did",
  "httr",
  "jsonlite",
  "modelsummary",
  "kableExtra",
  "HonestDiD",
  "sandwich",
  "lmtest"
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

DATA_DIR <- file.path(dirname(getwd()), "data")
TABLE_DIR <- file.path(dirname(getwd()), "tables")
FIG_DIR <- file.path(dirname(getwd()), "figures")

dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(TABLE_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(FIG_DIR, showWarnings = FALSE, recursive = TRUE)

cat("Packages loaded. Data dir:", DATA_DIR, "\n")
