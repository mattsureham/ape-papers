# ==============================================================================
# 00_packages.R — Load libraries and set themes
# apep_0600: EU Mortgage Credit Directive
# ==============================================================================

# CRAN packages
pkgs <- c(
  "data.table", "fixest", "ggplot2", "eurostat", "ecb",
  "httr", "jsonlite", "did", "knitr", "kableExtra",
  "sandwich", "lmtest", "boot", "fwildclusterboot",
  "HonestDiD", "purrr", "stringr", "lubridate", "scales"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

# eurlex package (CELLAR SPARQL)
if (!requireNamespace("eurlex", quietly = TRUE)) {
  install.packages("eurlex", repos = "https://cloud.r-project.org")
}
library(eurlex)

# ggplot theme
theme_set(
  theme_minimal(base_size = 11) +
    theme(
      panel.grid.minor = element_blank(),
      plot.title = element_text(face = "bold", size = 12),
      legend.position = "bottom"
    )
)

cat("All packages loaded.\n")
