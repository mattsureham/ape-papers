# =============================================================================
# 00_packages.R — Package Loading and Theme Setup
# APEP Paper apep_0547: No-Fault Eviction Abolition and Private Rental Supply
# =============================================================================

# Required packages
required_packages <- c(
  "data.table",     # Fast data manipulation
  "fixest",         # Fixed effects estimation (feols, sunab)
  "did",            # Callaway-Sant'Anna DiD
  "ggplot2",        # Plotting
  "scales",         # Axis formatting
  "modelsummary",   # Regression tables
  "kableExtra",     # Table formatting
  "HonestDiD",      # Rambachan-Roth sensitivity
  "fwildclusterboot", # Wild cluster bootstrap
  "sandwich",       # Robust SEs
  "lmtest",         # Hypothesis testing
  "curl",           # Download files
  "stringr",        # String operations
  "lubridate",      # Date handling
  "purrr"           # Functional programming
)

# Install missing packages
for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
}

# Load all packages
invisible(lapply(required_packages, library, character.only = TRUE))

# ggplot2 theme for publication
theme_apep <- theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "grey92"),
    plot.title = element_text(face = "bold", size = 12),
    plot.subtitle = element_text(size = 10, color = "grey40"),
    axis.title = element_text(size = 10),
    legend.position = "bottom",
    legend.title = element_text(size = 9),
    legend.text = element_text(size = 8),
    strip.text = element_text(face = "bold"),
    plot.margin = margin(10, 10, 10, 10)
  )
theme_set(theme_apep)

# Color palette
apep_colors <- c(
  "Wales"   = "#D62728",  # Red
  "England" = "#1F77B4",  # Blue
  "Border"  = "#2CA02C",  # Green
  "Placebo" = "#9467BD"   # Purple
)

cat("Packages loaded successfully.\n")
cat("R version:", R.version.string, "\n")
cat("fixest version:", as.character(packageVersion("fixest")), "\n")
cat("did version:", as.character(packageVersion("did")), "\n")
