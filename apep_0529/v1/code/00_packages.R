## 00_packages.R — Load libraries and set themes for apep_0529
## ZFE Scale Mismatch: National vs Local Climate Policy Divisiveness

options(repos = c(CRAN = "https://cloud.r-project.org"))
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(
  data.table, arrow, sf, jsonlite, httr2, xml2,
  fixest, did, HonestDiD,
  ggplot2, ggthemes, scales, patchwork, kableExtra,
  stringi, stringr
)

## ggplot theme
theme_set(theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    strip.text = element_text(face = "bold"),
    legend.position = "bottom"
  ))

## Colour palette
pal_zfe <- c(
  treated = "#D55E00",   # ZFE-active constituencies

  control = "#0072B2",   # Non-ZFE constituencies
  national = "#999999",  # National-level benchmark
  highlight = "#E69F00"  # Heterogeneity / spillback
)

cat("Packages loaded. R version:", R.version.string, "\n")
