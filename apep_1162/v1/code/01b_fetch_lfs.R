# 01b_fetch_lfs.R — Fetch LFS quarterly data at A*21 level
# apep_1162: Belgium SSC Cut — finer sector detail for n_treated ≥ 20

source("00_packages.R")
setwd(file.path(dirname(getwd()), "data"))

cat("=== Fetching LFS quarterly employment at A*21 level ===\n")

# Fetch for all countries (primary + expanded controls)
lfs_raw <- get_eurostat(
  "lfsq_egan22d",
  filters = list(
    geo = c("BE", "NL", "DE", "LU", "AT", "FR", "DK", "FI", "SE"),
    sex = "T",          # Total (both sexes)
    age = "Y15-64",     # Working age
    unit = "THS_PER"    # Thousands of persons
  ),
  time_format = "date"
)
stopifnot("Empty LFS data" = nrow(lfs_raw) > 0)
cat(sprintf("  LFS raw: %d rows\n", nrow(lfs_raw)))

# Aggregate 2-digit NACE to 1-letter (A*21)
library(stringr)
lfs_a21 <- lfs_raw |>
  mutate(
    nace1 = substr(as.character(nace_r2), 1, 1),
    year = year(time),
    quarter = quarter(time),
    yq = year + (quarter - 1) / 4,
    geo = as.character(geo)
  ) |>
  filter(yq >= 2013.0, yq <= 2019.75, !is.na(values)) |>
  group_by(geo, nace1, yq, year, quarter) |>
  summarise(emp = sum(values, na.rm = TRUE), .groups = "drop") |>
  filter(emp > 0)

cat(sprintf("  A*21 panel: %d obs\n", nrow(lfs_a21)))
cat(sprintf("  Countries: %s\n", paste(sort(unique(lfs_a21$geo)), collapse = ", ")))
cat(sprintf("  Sectors per country:\n"))
print(lfs_a21 |> group_by(geo) |> summarise(n_sectors = n_distinct(nace1)))

saveRDS(lfs_a21, "lfs_a21.rds")
cat("\nLFS A*21 data saved.\n")
