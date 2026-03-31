## 01_fetch_data.R — apep_1223: The Choice Tax
## Runs Python parsers then validates CSV outputs

source("00_packages.R")

cat("Running Python parsers...\n")
system2("python3", "01_fetch_data.py", stdout = TRUE, stderr = TRUE) |> cat(sep = "\n")
system2("python3", "01b_parse_extra.py", stdout = TRUE, stderr = TRUE) |> cat(sep = "\n")

# Validate outputs exist
data_dir <- "../data"
required <- c("panel_potsize_method.csv", "panel_age_detail.csv",
              "overview.csv", "advice_1824.csv",
              "panel_potsize_method_1518_supplement.csv")

for (f in required) {
  path <- file.path(data_dir, f)
  stopifnot(file.exists(path))
  n <- nrow(fread(path))
  cat(sprintf("  ✓ %s: %d rows\n", f, n))
}

cat("\nData fetch complete — all files validated.\n")
