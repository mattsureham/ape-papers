# =============================================================================
# 00_packages.R — Load libraries and set defaults
# Swiss Municipal Mergers and Democratic Participation
# =============================================================================

# --- Required packages -------------------------------------------------------
required_pkgs <- c(
  "data.table",     # Fast data manipulation
  "fixest",         # Fixed effects estimation (feols, sunab)
  "did",            # Callaway & Sant'Anna DiD
  "ggplot2",        # Visualization
  "ggthemes",       # Clean themes
  "patchwork",      # Combine plots
  "modelsummary",   # Tables
  "kableExtra",     # Table formatting
  "httr",           # API calls
  "jsonlite",       # JSON parsing
  "swissdd",        # Swiss referendum data
  "HonestDiD",      # Rambachan-Roth sensitivity
  "sandwich",       # Robust SEs
  "lmtest"          # Coefficient tests
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

# --- ggplot theme -------------------------------------------------------------
theme_apep <- theme_minimal(base_size = 12, base_family = "serif") +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 11, color = "gray40"),
    axis.title = element_text(size = 11),
    legend.position = "bottom",
    strip.text = element_text(face = "bold")
  )
theme_set(theme_apep)

# --- Paths --------------------------------------------------------------------
DATA_DIR   <- file.path(dirname(getwd()), "data")
FIG_DIR    <- file.path(dirname(getwd()), "figures")
TABLE_DIR  <- file.path(dirname(getwd()), "tables")

dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(FIG_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(TABLE_DIR, showWarnings = FALSE, recursive = TRUE)

cat("Packages loaded. Data dir:", DATA_DIR, "\n")
