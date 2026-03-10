## 00_packages.R — Install and load required packages
## APEP Paper apep_0584: Oregon Drug Decriminalization Symmetric Test

required <- c(
  "tidyverse", "data.table", "jsonlite", "httr",
  "augsynth",    # Ben-Michael et al. (2021) augmented synthetic control
  "Synth",       # Abadie et al. (2010) classic SCM
  "fixest",      # high-dimensional fixed effects (for auxiliary regressions)
  "ggthemes",    # clean plotting themes
  "scales",      # axis formatting
  "patchwork",   # combining plots
  "kableExtra"   # LaTeX table formatting
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

# APEP theme
theme_apep <- theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold", size = 13),
    plot.subtitle = element_text(size = 11, color = "grey40"),
    axis.title = element_text(size = 11),
    legend.position = "bottom",
    plot.caption = element_text(size = 8, color = "grey50")
  )
theme_set(theme_apep)

cat("All packages loaded successfully.\n")
