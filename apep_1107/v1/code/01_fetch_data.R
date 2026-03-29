## 01_fetch_data.R — Fetch Eurostat Labour Cost Index data
## apep_1107: Romania Overnight Payroll Tax Shift

source("00_packages.R")

cat("=== Fetching Eurostat Labour Cost Index (lc_lci_r2_q) ===\n")

## ── Primary data: Labour Cost Index ──────────────────────────────────
## Table lc_lci_r2_q: quarterly LCI by NACE sector x country
## Variables: D11 (wages/salaries), D12_D4_MD5 (non-wage costs)
## Index: 2020 = 100 (seasonally + calendar adjusted)

lci_raw <- get_eurostat("lc_lci_r2_q", time_format = "date")

if (is.null(lci_raw) || nrow(lci_raw) == 0) {
  stop("FATAL: Eurostat API returned empty data for lc_lci_r2_q. Cannot proceed.")
}

cat(sprintf("  Downloaded %d rows from lc_lci_r2_q\n", nrow(lci_raw)))
cat(sprintf("  Countries: %s\n", paste(sort(unique(lci_raw$geo)), collapse = ", ")))
cat(sprintf("  Date range: %s to %s\n", min(lci_raw$TIME_PERIOD), max(lci_raw$TIME_PERIOD)))
cat(sprintf("  LCI types: %s\n", paste(sort(unique(lci_raw$lcstruct)), collapse = ", ")))

## ── Filter to relevant variables and time window ─────────────────────
## Keep: D11 (wages), D12_D4_MD5 (non-wage), D1_D4_MD5 (total)
## Seasonally + calendar adjusted (SCA)
## NACE sectors: B-S aggregate and individual sectors
## Time: 2012-Q1 to 2019-Q4 (stop before COVID)

lci <- lci_raw |>
  filter(
    s_adj == "SCA",                           # seasonally + calendar adjusted
    unit == "I20",                            # index 2020=100
    lcstruct %in% c("D11", "D12_D4_MD5", "D1_D4_MD5"),  # wages, non-wage, total
    TIME_PERIOD >= as.Date("2012-01-01"),
    TIME_PERIOD <= as.Date("2019-12-31")
  ) |>
  rename(time = TIME_PERIOD) |>
  mutate(
    year = as.integer(format(time, "%Y")),
    quarter = (as.integer(format(time, "%m")) - 1) %/% 3 + 1,
    yq = year + (quarter - 1) / 4,
    component = case_when(
      lcstruct == "D11"        ~ "wages",
      lcstruct == "D12_D4_MD5" ~ "nonwage",
      lcstruct == "D1_D4_MD5"  ~ "total",
      TRUE                     ~ NA_character_
    ),
    country = geo,
    sector = nace_r2
  ) |>
  filter(!is.na(component), !is.na(values)) |>
  select(country, sector, time, year, quarter, yq, component, values)

cat(sprintf("  After filtering: %d observations\n", nrow(lci)))
cat(sprintf("  Countries: %d unique\n", n_distinct(lci$country)))
cat(sprintf("  Sectors: %s\n", paste(sort(unique(lci$sector)), collapse = ", ")))

## ── Validate Romania data exists ─────────────────────────────────────
ro_obs <- lci |> filter(country == "RO")
if (nrow(ro_obs) == 0) {
  stop("FATAL: No Romania data in LCI. Cannot proceed.")
}
cat(sprintf("  Romania observations: %d\n", nrow(ro_obs)))
cat(sprintf("  Romania sectors: %s\n", paste(sort(unique(ro_obs$sector)), collapse = ", ")))

## ── Remove aggregate geo codes (EU, EA, non-member) ──────────────────
aggregate_geos <- c("EU", "EU15", "EU27_2020", "EU28", "EA", "EA19", "EA20", "EA21")
non_eu <- c("IS", "NO", "RS", "TR", "UK")  # keep only EU members pre-Brexit period
lci <- lci |>
  filter(!country %in% c(aggregate_geos, non_eu))

cat(sprintf("  After removing aggregates: %d rows, %d countries\n",
            nrow(lci), n_distinct(lci$country)))

## ── Define treatment ─────────────────────────────────────────────────
## Treatment: Romania, post 2018-Q1
lci <- lci |>
  mutate(
    treated_country = as.integer(country == "RO"),
    post = as.integer(time >= as.Date("2018-01-01")),
    treat_post = treated_country * post
  )

## ── Define country groups ────────────────────────────────────────────
cee_countries <- c("RO", "BG", "HU", "PL", "CZ", "SK")
eu_countries <- unique(lci$country)

lci <- lci |>
  mutate(
    cee = as.integer(country %in% cee_countries),
    country_group = case_when(
      country == "RO" ~ "Romania",
      country %in% cee_countries ~ "CEE peers",
      TRUE ~ "Other EU"
    )
  )

## ── Save processed data ─────────────────────────────────────────────
saveRDS(lci, "../data/lci_panel.rds")
cat(sprintf("\n  Saved lci_panel.rds: %d rows, %d countries, %d sectors\n",
            nrow(lci), n_distinct(lci$country), n_distinct(lci$sector)))

## ── Quick smoke test output ──────────────────────────────────────────
cat("\n=== Smoke Test: Romania Q4 2017 vs Q1 2018 ===\n")
smoke <- lci |>
  filter(country == "RO", sector == "B-S",
         time %in% as.Date(c("2017-10-01", "2018-01-01"))) |>
  select(time, component, values) |>
  pivot_wider(names_from = component, values_from = values)
print(smoke)

cat("\n=== Data fetch complete ===\n")
