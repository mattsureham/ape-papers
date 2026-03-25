## 00_packages.R — Install and load required packages
## apep_0944: AVR and Federal Jury Acquittal Rates

required <- c(
  "tidyverse", "data.table", "fixest", "did", "jsonlite",
  "sandwich", "lmtest", "xtable", "HonestDiD"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
