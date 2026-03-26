# =============================================================================
# 01_fetch_data.R — Load QWI data (fetched via 01_fetch_data.py from Azure)
# =============================================================================

source("00_packages.R")

# Data was downloaded from Azure by 01_fetch_data.py
# Read and validate
stopifnot("Run 01_fetch_data.py first" = file.exists("../data/qwi_rh_ns_raw.parquet"))

df_raw <- arrow::read_parquet("../data/qwi_rh_ns_raw.parquet")

cat(sprintf("Rows loaded: %s\n", format(nrow(df_raw), big.mark = ",")))
cat(sprintf("Columns: %d\n", ncol(df_raw)))
cat(sprintf("Industries: %s\n", paste(unique(df_raw$industry), collapse = ", ")))
cat(sprintf("Years: %d to %d\n", min(df_raw$year), max(df_raw$year)))
cat(sprintf("Race codes: %s\n", paste(sort(unique(df_raw$race)), collapse = ", ")))
cat(sprintf("Ethnicity codes: %s\n", paste(sort(unique(df_raw$ethnicity)), collapse = ", ")))

stopifnot("No data" = nrow(df_raw) > 0)
stopifnot("Missing EarnS" = "EarnS" %in% names(df_raw))
stopifnot("Missing Emp" = "Emp" %in% names(df_raw))

cat("Data validation passed.\n")
