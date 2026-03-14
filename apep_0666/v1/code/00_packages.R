## 00_packages.R — apep_0666: EU smoking bans
required_packages <- c("tidyverse", "fixest", "did", "jsonlite", "httr", "readr")
for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE))
    install.packages(pkg, repos = "https://cloud.r-project.org")
  library(pkg, character.only = TRUE)
}
cat("All packages loaded.\n")
