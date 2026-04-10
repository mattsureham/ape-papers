pkgs <- c(
  "tidyverse", "jsonlite", "httr", "rdrobust", "rddensity",
  "fixest", "sandwich", "lmtest", "modelsummary", "kableExtra"
)
for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}
