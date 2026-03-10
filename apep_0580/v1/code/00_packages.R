## ============================================================
## 00_packages.R — Load and verify all required packages
## apep_0580: Civil Asset Forfeiture Reform and Police Reallocation
## ============================================================

required_pkgs <- c(
  "tidyverse",      # data wrangling + ggplot2
  "data.table",     # fast data operations
  "fixest",         # TWFE and Sun-Abraham estimator
  "did",            # Callaway & Sant'Anna
  "haven",          # read Stata .dta files
  "readxl",         # read Excel files
  "rvest",          # web scraping for reform dates
  "jsonlite",       # JSON parsing
  "sandwich",       # robust SEs
  "lmtest",         # coefficient tests
  "xtable",         # LaTeX tables
  "modelsummary",   # regression tables
  "kableExtra",     # table formatting
  "scales",         # axis formatting
  "patchwork"       # combine plots
)

# Optional packages (may fail to install due to system deps)
optional_pkgs <- c("HonestDiD", "fwildclusterboot")

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

for (pkg in optional_pkgs) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    library(pkg, character.only = TRUE)
    cat("  Optional package loaded:", pkg, "\n")
  } else {
    cat("  Optional package not available:", pkg, "(skipping)\n")
  }
}

# ggplot theme for APEP
theme_apep <- theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    plot.title = element_text(face = "bold", size = 13),
    plot.subtitle = element_text(size = 10, color = "gray40"),
    axis.title = element_text(size = 11),
    legend.position = "bottom"
  )
theme_set(theme_apep)

cat("All packages loaded successfully.\n")
cat("R version:", R.version.string, "\n")
