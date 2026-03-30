# ─── Load required packages ──────────────────────────────────────────────────
pkgs <- c("data.table", "fixest", "duckdb", "DBI", "ivreg", "sandwich", "lmtest")
for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}
cat("All packages loaded.\n")
