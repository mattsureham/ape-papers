## 00_packages.R — Install and load required packages
## apep_0966: EU Menthol Cigarette Ban

# Set working directory to the paper root (one level up from code/)
if (basename(getwd()) == "code") setwd("..")

required_packages <- c(
  "tidyverse",
  "fixest",
  "eurostat",
  "httr",
  "jsonlite",
  "sandwich",
  "lmtest",
  "fwildclusterboot",
  "modelsummary",
  "kableExtra"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
