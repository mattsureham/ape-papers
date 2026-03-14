# 00_packages.R — Load required libraries
# apep_0685: Canada carbon pricing backstop

required_packages <- c(
 "tidyverse", "fixest", "did", "data.table", "jsonlite",
 "sandwich", "lmtest", "kableExtra",
 "modelsummary", "xtable"
)

for (pkg in required_packages) {
 if (!requireNamespace(pkg, quietly = TRUE)) {
   install.packages(pkg, repos = "https://cloud.r-project.org")
 }
 library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
