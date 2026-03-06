## 00_packages.R — Load libraries and set global options
## apep_0534 v2: Green Patent Examiner Leniency IV (Application-Level)

# Core data manipulation
library(data.table)
library(arrow)

# Econometrics
library(fixest)
library(sandwich)
library(lmtest)

# Figures and tables
library(ggplot2)
library(patchwork)
library(scales)
library(kableExtra)

# Utilities
library(stringr)
library(glue)

# ggplot theme
theme_set(
  theme_minimal(base_size = 11) +
    theme(
      plot.title = element_text(face = "bold", size = 12),
      strip.text = element_text(face = "bold"),
      legend.position = "bottom",
      panel.grid.minor = element_blank()
    )
)

# Paths — robust resolution that works with Rscript and source()
BASE <- tryCatch(
  normalizePath(file.path(dirname(sys.frame(1)$ofile), ".."), mustWork = FALSE),
  error = function(e) {
    wd <- getwd()
    if (basename(wd) == "code") dirname(wd)
    else if (dir.exists(file.path(wd, "code"))) wd
    else wd
  }
)
if (!dir.exists(BASE)) BASE <- getwd()
DATA_DIR  <- file.path(BASE, "data")
FIG_DIR   <- file.path(BASE, "figures")
TAB_DIR   <- file.path(BASE, "tables")
CODE_DIR  <- file.path(BASE, "code")

dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(FIG_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(TAB_DIR, showWarnings = FALSE, recursive = TRUE)

cat("Packages loaded. BASE:", BASE, "\n")
