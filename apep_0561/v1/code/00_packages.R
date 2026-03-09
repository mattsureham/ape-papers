## 00_packages.R — Load and install required packages
## apep_0561: ZRR reclassification and RN voting

required_packages <- c(
  "data.table", "fixest", "ggplot2", "dplyr", "tidyr", "readr",
  "sf", "rdrobust", "rddensity", "did", "HonestDiD",
  "modelsummary", "kableExtra", "xtable", "scales",
  "broom", "sandwich", "lmtest", "purrr", "stringr",
  "curl", "jsonlite", "arrow"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

# Set global ggplot theme
theme_set(
  theme_minimal(base_size = 12) +
    theme(
      panel.grid.minor = element_blank(),
      plot.title = element_text(face = "bold", size = 14),
      axis.title = element_text(size = 11),
      legend.position = "bottom"
    )
)

cat("All packages loaded successfully.\n")
