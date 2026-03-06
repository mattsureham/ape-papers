###############################################################################
# 00_packages.R — Load and install required packages
# APEP-0541: How Many Generics Does It Take?
###############################################################################

required_pkgs <- c(
  "tidyverse",     # data manipulation + ggplot2

"data.table",    # fast I/O
  "fixest",        # fixed effects estimation
  "did",           # Callaway-Sant'Anna
  "latex2exp",     # LaTeX in ggplot
  "modelsummary",  # regression tables
  "kableExtra",    # table formatting
  "jsonlite",      # JSON parsing
  "httr",          # HTTP requests
  "lubridate",     # date handling
  "scales",        # axis formatting
  "patchwork"      # combining plots
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

# APEP standard theme
theme_apep <- function() {
  theme_minimal(base_size = 12) +
    theme(
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(color = "grey90", linewidth = 0.3),
      axis.line = element_line(color = "grey30", linewidth = 0.4),
      axis.ticks = element_line(color = "grey30", linewidth = 0.3),
      axis.title = element_text(size = 11, face = "bold"),
      axis.text = element_text(size = 10, color = "grey30"),
      legend.position = "bottom",
      legend.title = element_text(size = 10, face = "bold"),
      legend.text = element_text(size = 9),
      plot.title = element_text(size = 13, face = "bold", hjust = 0),
      plot.subtitle = element_text(size = 10, color = "grey40", hjust = 0),
      plot.caption = element_text(size = 8, color = "grey50", hjust = 1),
      plot.margin = margin(10, 15, 10, 10)
    )
}

apep_colors <- c(
  "#0072B2", "#D55E00", "#009E73", "#CC79A7", "#F0E442",
  "#56B4E9", "#E69F00", "#000000", "#999999"
)

cat("All packages loaded successfully.\n")
