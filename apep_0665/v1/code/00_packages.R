## 00_packages.R — apep_0665: Italy Fornero pension reform
required_packages <- c("tidyverse", "fixest", "jsonlite", "httr", "readr")
for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE))
    install.packages(pkg, repos = "https://cloud.r-project.org")
  library(pkg, character.only = TRUE)
}
cat("All packages loaded.\n")
