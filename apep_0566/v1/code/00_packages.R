# ============================================================================
# 00_packages.R — Load all required packages
# APEP Paper apep_0566: Civil Asset Forfeiture Reform and Drug Overdose Mortality
# ============================================================================

cat("Loading packages...\n")

required_pkgs <- c(
  "data.table", "dplyr", "tidyr", "ggplot2", "stringr", "readr",
  "httr", "jsonlite",       # API access
  "did",                    # Callaway-Sant'Anna
  "fixest",                 # Sun-Abraham, fast TWFE
  "HonestDiD",              # Rambachan-Roth sensitivity
  "bacondecomp",            # Goodman-Bacon decomposition
  "fwildclusterboot",       # Wild cluster bootstrap
  "modelsummary",           # Table formatting
  "ggthemes",               # Plot themes
  "scales",                 # Axis formatting
  "knitr", "kableExtra"     # Table export
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cat("Installing:", pkg, "\n")
    install.packages(pkg, repos = "https://cran.r-project.org", quiet = TRUE)
  }
  suppressPackageStartupMessages(library(pkg, character.only = TRUE))
}

# Set consistent plot theme
theme_apep <- theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold", size = 13),
    plot.subtitle = element_text(size = 10, color = "gray40"),
    legend.position = "bottom",
    strip.text = element_text(face = "bold")
  )
theme_set(theme_apep)

cat("All packages loaded successfully.\n")
