# ============================================================
# 00_packages.R — apep_0765
# ============================================================
required_packages <- c(
  "tidyverse", "fixest", "data.table", "httr", "jsonlite",
  "lubridate", "xtable", "kableExtra"
)
for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE))
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  library(pkg, character.only = TRUE)
}
cat("All packages loaded.\n")
