# ==============================================================================
# 00_packages.R — Load libraries and set themes
# Clean Air, Dirty Power? NAAQS Nonattainment and the Clean Energy Transition
# ==============================================================================

# --- Required packages ---
pkgs <- c(
  "tidyverse",    # data manipulation and viz
  "data.table",   # fast data operations
  "fixest",       # fixed effects regressions
  "rdrobust",     # RDD estimation (Calonico, Cattaneo, Titiunik)
  "rddensity",    # McCrary density test (Cattaneo, Jansson, Ma)
  "rdmulti",      # Multi-cutoff RDD
  "modelsummary", # regression tables
  "kableExtra",   # table formatting
  "ggthemes",     # theme_clean
  "scales",       # scale formatting
  "httr",         # API calls
  "jsonlite",     # JSON parsing
  "sf"            # spatial analysis (for neighbor counties)
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

# --- ggplot2 theme ---
theme_set(
  theme_minimal(base_size = 12) +
    theme(
      panel.grid.minor = element_blank(),
      plot.title = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(color = "grey40"),
      legend.position = "bottom",
      strip.text = element_text(face = "bold")
    )
)

# --- Paths ---
data_dir   <- file.path(dirname(getwd()), "data")
fig_dir    <- file.path(dirname(getwd()), "figures")
tab_dir    <- file.path(dirname(getwd()), "tables")
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(tab_dir, showWarnings = FALSE, recursive = TRUE)

cat("Packages loaded, theme set, paths configured.\n")
