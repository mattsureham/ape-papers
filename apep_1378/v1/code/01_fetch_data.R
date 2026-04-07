# Fetch FDIC call report data from public CSV downloads
source("00_packages.R")

cat("Downloading FDIC call report data from public repository...\n")

url <- "https://www.fdic.gov/bank/statistical/statistics/2024/q4_all_banks.csv"

cat("Attempting download from FDIC...\n")

fdic_raw <- read_csv(url, show_col_types = FALSE)

cat(sprintf("Downloaded %d rows\n", nrow(fdic_raw)))
cat(sprintf("Columns: %s\n", paste(names(fdic_raw)[1:10], collapse = ", ")))

fdic <- fdic_raw |>
  rename_with(tolower) |>
  mutate(
    across(everything(), as.numeric),
    year = 2024,
    quarter = 4
  ) |>
  select(cert, year, quarter,
         npl = npl,
         tier1_ratio = tier1capital,
         assets = totalassets) |>
  filter(!is.na(cert), !is.na(assets), assets > 0)

cat(sprintf("Processed %d banks\n", n_distinct(fdic$cert)))

write_csv(fdic, "data/fdic_calls_clean.csv")

write_json(list(
  n_banks = n_distinct(fdic$cert),
  n_obs = nrow(fdic),
  year = 2024,
  source = "FDIC public quarterly report"
), "data/diagnostics.json", auto_unbox = TRUE)

print(head(fdic))
