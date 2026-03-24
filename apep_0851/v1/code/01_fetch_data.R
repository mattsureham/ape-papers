## 01_fetch_data.R — Fetch Eurostat House Price Index data
## apep_0851: Abolishing the Tax Haven Next Door

source("00_packages.R")

cat("=== Fetching Eurostat HPI (prc_hpi_q) ===\n")

# -----------------------------------------------------------------------
# 1. Eurostat HPI — quarterly house price index (2005Q1–latest)
# -----------------------------------------------------------------------
# The eurostat package fetches via the Eurostat bulk download / JSON-stat API
hpi_raw <- get_eurostat("prc_hpi_q", time_format = "date")

stopifnot("Eurostat HPI download returned zero rows" = nrow(hpi_raw) > 0)
cat("  Raw HPI rows:", nrow(hpi_raw), "\n")

# Keep total purchases (TOTAL), deflated (not nominal) not needed —
# we use index 2015=100 (I15_Q)
hpi <- hpi_raw %>%
  filter(
    purchase == "TOTAL",       # all purchases (new + existing)
    unit     == "I15_Q"        # Index 2015 = 100
  ) %>%
  mutate(
    country  = geo,
    date     = as.Date(TIME_PERIOD),
    year     = as.integer(format(date, "%Y")),
    quarter  = as.integer(format(date, "%m")) %/% 3 + 1L,
    yq       = year + (quarter - 1) / 4,   # numeric year-quarter
    log_hpi  = log(values)
  ) %>%
  select(country, date, year, quarter, yq, hpi = values, log_hpi) %>%
  filter(year >= 2010, year <= 2025) %>%
  arrange(country, date)

cat("  Filtered HPI rows:", nrow(hpi), "\n")
cat("  Countries:", length(unique(hpi$country)), "\n")
cat("  Date range:", as.character(min(hpi$date)), "to", as.character(max(hpi$date)), "\n")

# Verify Portugal is present
pt_obs <- hpi %>% filter(country == "PT")
stopifnot("Portugal not found in HPI data" = nrow(pt_obs) > 0)
cat("  Portugal obs:", nrow(pt_obs), "\n")

# -----------------------------------------------------------------------
# 2. Also fetch new vs existing dwellings (mechanism test)
# -----------------------------------------------------------------------
cat("\n=== Fetching Eurostat HPI by new/existing ===\n")
hpi_oo_raw <- tryCatch(
  get_eurostat("prc_hpi_oo", time_format = "date"),
  error = function(e) {
    cat("  prc_hpi_oo not available:", conditionMessage(e), "\n")
    tibble()
  }
)

if (nrow(hpi_oo_raw) > 0) {
  hpi_oo <- hpi_oo_raw %>%
    filter(unit == "I15_Q") %>%
    mutate(
      country  = geo,
      date     = as.Date(TIME_PERIOD),
      year     = as.integer(format(date, "%Y")),
      quarter  = as.integer(format(date, "%m")) %/% 3 + 1L,
      yq       = year + (quarter - 1) / 4,
      dwelling_type = case_when(
        n_existing == "N"  ~ "new",
        n_existing == "E"  ~ "existing",
        n_existing == "TOTAL" ~ "total",
        TRUE ~ as.character(n_existing)
      ),
      log_hpi = log(values)
    ) %>%
    select(country, date, year, quarter, yq, dwelling_type, hpi = values, log_hpi) %>%
    filter(year >= 2010, year <= 2025) %>%
    arrange(country, date)
  cat("  HPI by dwelling type rows:", nrow(hpi_oo), "\n")
} else {
  cat("  WARNING: prc_hpi_oo returned no data, skipping dwelling-type split.\n")
  hpi_oo <- tibble()
}

# -----------------------------------------------------------------------
# 3. Save
# -----------------------------------------------------------------------
write_csv(hpi, "../data/hpi_eurostat.csv")
if (nrow(hpi_oo) > 0) write_csv(hpi_oo, "../data/hpi_by_dwelling.csv")

cat("\n=== Data fetch complete ===\n")
cat("  Main HPI saved to data/hpi_eurostat.csv\n")
