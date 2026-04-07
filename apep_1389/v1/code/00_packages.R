## 00_packages.R — Load required packages
pkgs <- c("data.table", "fixest", "ggplot2", "rdrobust", "rddensity",
          "jsonlite", "readr", "stringr", "binsreg", "xtable", "scales")
for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

# Set consistent theme
theme_set(theme_minimal(base_size = 12) +
  theme(panel.grid.minor = element_blank(),
        plot.title = element_text(face = "bold", size = 14),
        axis.title = element_text(size = 11)))
