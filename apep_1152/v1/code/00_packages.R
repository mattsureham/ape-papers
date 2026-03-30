## 00_packages.R — The Stranded Signal (apep_1152)
required_packages <- c("data.table", "fixest", "did", "modelsummary", "jsonlite")
for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE))
    install.packages(pkg, repos = "https://cloud.r-project.org")
  library(pkg, character.only = TRUE)
}
cat("All packages loaded.\n")
if (!requireNamespace("here", quietly = TRUE)) install.packages("here", repos = "https://cloud.r-project.org")
library(here)
