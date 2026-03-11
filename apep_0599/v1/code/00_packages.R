# ============================================================================
# 00_packages.R — Package loading and theme setup
# Denmark's 2013 Disability Pension Reform (apep_0599)
# ============================================================================

required_packages <- c(
  "data.table", "httr", "jsonlite",   # Data acquisition
  "fixest", "did",                      # Econometrics
  "ggplot2", "ggthemes", "scales",      # Visualization
  "knitr", "kableExtra",               # Tables
  "sandwich", "lmtest",                # Robust inference
  "boot"                               # Bootstrap
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

# --- ggplot2 theme ---
theme_apep <- theme_minimal(base_size = 12, base_family = "serif") +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "grey90"),
    axis.line = element_line(color = "black", linewidth = 0.3),
    axis.ticks = element_line(color = "black", linewidth = 0.3),
    plot.title = element_text(face = "bold", size = 13),
    plot.subtitle = element_text(size = 10, color = "grey30"),
    legend.position = "bottom",
    strip.text = element_text(face = "bold")
  )
theme_set(theme_apep)

# Color palette
cols_apep <- c(
  "High (25-39)" = "#D62728",   # Red — high treatment intensity
  "Moderate (40-49)" = "#FF7F0E", # Orange — moderate intensity
  "Control (50-59)" = "#1F77B4"  # Blue — control
)

cat("Packages loaded successfully.\n")
