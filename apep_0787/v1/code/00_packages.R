## 00_packages.R — Install/load required packages
## apep_0787: PSL mandates and workplace injuries

required <- c(
  "tidyverse", "data.table", "fixest", "did", "jsonlite",
  "kableExtra", "xtable", "httr", "readr", "janitor"
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
