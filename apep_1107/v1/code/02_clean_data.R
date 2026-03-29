## 02_clean_data.R — Construct analysis panel
## apep_1107: Romania Overnight Payroll Tax Shift

source("00_packages.R")

lci <- readRDS("../data/lci_panel.rds")

cat("=== Constructing analysis panel ===\n")

## ── Reshape to wide: one row per country x sector x quarter ──────────
panel <- lci |>
  pivot_wider(
    id_cols = c(country, sector, time, year, quarter, yq,
                treated_country, post, treat_post, cee, country_group),
    names_from = component,
    values_from = values
  )

cat(sprintf("  Panel: %d rows (country x sector x quarter)\n", nrow(panel)))

## ── Drop rows with missing wage or non-wage data ─────────────────────
panel <- panel |>
  filter(!is.na(wages), !is.na(nonwage))

cat(sprintf("  After dropping missing: %d rows\n", nrow(panel)))

## ── Construct derived variables ──────────────────────────────────────
panel <- panel |>
  mutate(
    log_wages = log(wages),
    log_nonwage = log(nonwage),
    log_total = log(total),
    nonwage_share = nonwage / (wages + nonwage),  # share of non-wage in total comp
    # Event time: quarters relative to 2018-Q1
    event_time = (year - 2018) * 4 + (quarter - 1),
    # Create numeric IDs for FE estimation
    country_sector = paste0(country, "_", sector),
    country_quarter = paste0(country, "_", year, "Q", quarter),
    sector_quarter = paste0(sector, "_", year, "Q", quarter)
  )

## ── Core sample: CEE countries, aggregate sector (B-S) ───────────────
core_agg <- panel |>
  filter(country %in% c("RO", "BG", "HU", "PL", "CZ", "SK"),
         sector == "B-S")

cat(sprintf("  Core aggregate sample: %d rows (6 CEE x 1 sector x quarters)\n", nrow(core_agg)))

## ── Extended sample: CEE countries, all available sectors ────────────
## Exclude aggregate and total industry to avoid double-counting
sector_codes <- panel |>
  filter(country %in% c("RO", "BG", "HU", "PL", "CZ", "SK"),
         !sector %in% c("B-S", "B-S_X_O")) |>
  pull(sector) |>
  unique()

core_sectors <- panel |>
  filter(country %in% c("RO", "BG", "HU", "PL", "CZ", "SK"),
         sector %in% sector_codes)

cat(sprintf("  Core sector sample: %d rows (%d sectors)\n",
            nrow(core_sectors), n_distinct(core_sectors$sector)))
cat(sprintf("  Sectors included: %s\n", paste(sort(sector_codes), collapse = ", ")))

## ── Full EU sample: all countries, aggregate sector ──────────────────
full_agg <- panel |>
  filter(sector == "B-S")

cat(sprintf("  Full EU aggregate sample: %d rows (%d countries)\n",
            nrow(full_agg), n_distinct(full_agg$country)))

## ── Balance check ────────────────────────────────────────────────────
balance <- core_sectors |>
  group_by(country, sector) |>
  summarise(n_quarters = n(), .groups = "drop") |>
  group_by(country) |>
  summarise(
    n_sectors = n(),
    min_q = min(n_quarters),
    max_q = max(n_quarters),
    .groups = "drop"
  )
cat("\n=== Panel balance by country ===\n")
print(balance)

## ── Save all panels ─────────────────────────────────────────────────
saveRDS(panel, "../data/panel_full.rds")
saveRDS(core_agg, "../data/core_agg.rds")
saveRDS(core_sectors, "../data/core_sectors.rds")
saveRDS(full_agg, "../data/full_agg.rds")

cat("\n=== Panel construction complete ===\n")
