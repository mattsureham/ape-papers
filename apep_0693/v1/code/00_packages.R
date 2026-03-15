## 00_packages.R — Install and load required packages
## apep_0693: The Price of Privacy

pkgs <- c(
  "tidyverse", "fixest", "did", "data.table",
  "modelsummary", "kableExtra", "jsonlite"
)

# Optional packages (may not be available for all R versions)
opt_pkgs <- c("fwildclusterboot", "HonestDiD")
for (p in opt_pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    tryCatch(
      install.packages(p, repos = "https://cloud.r-project.org"),
      error = function(e) cat(sprintf("Optional package %s not available.\n", p))
    )
  }
  if (requireNamespace(p, quietly = TRUE)) library(p, character.only = TRUE)
}

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
