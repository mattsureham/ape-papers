## 00_packages.R — Load required packages
## Paper: The Bureaucrat's Bonus (apep_0821)

pkgs <- c("data.table", "fixest", "xtable", "jsonlite")
for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}
cat("All packages loaded.\n")
