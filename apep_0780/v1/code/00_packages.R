## 00_packages.R — Load required packages
## apep_0780: Insured into Monoculture?

pkgs <- c("tidyverse", "fixest", "did", "data.table", "jsonlite", "httr2", "kableExtra")
for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cran.r-project.org")
  library(p, character.only = TRUE)
}
cat("All packages loaded.\n")
