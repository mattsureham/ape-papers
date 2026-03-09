## 00_packages.R — Load required packages for sanctions trade analysis
## apep_0553: Do Export Controls Have Teeth?

required_packages <- c(
  "data.table", "fixest", "ggplot2",
  "sandwich", "lmtest", "modelsummary", "kableExtra",
  "scales", "purrr", "stringr", "glue",
  "fwildclusterboot"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

## ggplot theme for publication (AER/QJE style: white background, minimal grids)
theme_set(theme_bw(base_size = 11) +
            theme(
              panel.grid.minor = element_blank(),
              panel.grid.major = element_line(color = "grey92", linewidth = 0.3),
              plot.title = element_text(face = "bold", size = 12),
              plot.subtitle = element_text(size = 10, color = "grey30"),
              legend.position = "bottom",
              strip.text = element_text(face = "bold"),
              axis.line = element_line(color = "black", linewidth = 0.3)
            ))

cat("Packages loaded successfully.\n")
