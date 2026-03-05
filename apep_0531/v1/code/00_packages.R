## ============================================================
## 00_packages.R — Install and load required packages
## apep_0531: PCSO Cuts and Crime in England
## ============================================================

required_pkgs <- c(
  "data.table", "readODS", "readxl", "httr2", "jsonlite",
  "fixest", "did", "HonestDiD", "fwildclusterboot",
  "ggplot2", "ggthemes", "patchwork", "scales",
  "kableExtra", "modelsummary",
  "sf", "spdep"
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

# Set consistent theme
theme_set(theme_minimal(base_size = 11) +
            theme(panel.grid.minor = element_blank(),
                  plot.title = element_text(face = "bold", size = 12),
                  strip.text = element_text(face = "bold")))

# Output directories
fig_dir <- "../figures/"
tab_dir <- "../tables/"
dat_dir <- "../data/"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(tab_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(dat_dir, showWarnings = FALSE, recursive = TRUE)

cat("Packages loaded. Output directories ready.\n")
