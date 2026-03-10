# 00_packages.R — Package loading and global settings
# apep_0582: The Resilience Puzzle — European Manufacturing and the Russian Gas Shock

required_packages <- c(
  "data.table", "fixest", "ggplot2", "eurostat", "httr", "jsonlite",
  "dplyr", "tidyr", "stringr", "purrr", "readr", "scales",
  "sandwich", "lmtest", "fwildclusterboot", "xtable", "kableExtra",
  "viridis"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

# Global ggplot theme
theme_set(
  theme_minimal(base_size = 11) +
    theme(
      panel.grid.minor = element_blank(),
      plot.title = element_text(face = "bold", size = 12),
      plot.subtitle = element_text(size = 10, color = "grey40"),
      legend.position = "bottom"
    )
)

# Paths
data_dir  <- file.path(dirname(getwd()), "data")
fig_dir   <- file.path(dirname(getwd()), "figures")
tab_dir   <- file.path(dirname(getwd()), "tables")
dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir,  showWarnings = FALSE, recursive = TRUE)
dir.create(tab_dir,  showWarnings = FALSE, recursive = TRUE)

cat("Packages loaded. Directories set.\n")
cat("  data_dir:", data_dir, "\n")
cat("  fig_dir:",  fig_dir,  "\n")
cat("  tab_dir:",  tab_dir,  "\n")
